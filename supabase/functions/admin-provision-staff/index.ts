import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const APP_URL =
  Deno.env.get('APP_URL') ?? 'https://mellow-longma-638c7a.netlify.app';

function readJsonSecret(name: string): string {
  const raw = Deno.env.get(name) ?? '';
  if (!raw) return '';

  try {
    const parsed = JSON.parse(raw);
    if (typeof parsed === 'string') return parsed;
    if (parsed && typeof parsed.default === 'string') return parsed.default;
  } catch (_) {
    // Local/legacy environments may expose the value directly.
  }

  return raw;
}

// Current Supabase secret names first; legacy names remain a fallback so the
// deployed function can continue working while projects migrate their secrets.
const SUPABASE_PUBLISHABLE_KEY =
  readJsonSecret('SUPABASE_PUBLISHABLE_KEYS') ||
  Deno.env.get('SUPABASE_ANON_KEY') ||
  '';

const SUPABASE_SECRET_KEY =
  readJsonSecret('SUPABASE_SECRET_KEYS') ||
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ||
  '';

const allowedRoles = new Set([
  'DRIVER',
  'DOCTOR',
  'CUSTOMER_CARE',
  'TEAM_LEAD',
]);

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function requiredString(value: unknown, field: string): string {
  const result = String(value ?? '').trim();
  if (!result) throw new Error(`${field} is required.`);
  return result;
}

function log(stage: string, details?: Record<string, unknown>) {
  console.log(
    `[admin-provision-staff] ${stage}`,
    details ? JSON.stringify(details) : '',
  );
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed.' }, 405);
  }

  if (!SUPABASE_URL || !SUPABASE_PUBLISHABLE_KEY || !SUPABASE_SECRET_KEY) {
    log('SERVER CONFIGURATION INCOMPLETE');
    return json(
      { error: 'Server authentication configuration is incomplete.' },
      500,
    );
  }

  const authorization = req.headers.get('Authorization');
  if (!authorization?.startsWith('Bearer ')) {
    return json({ error: 'Authentication is required.' }, 401);
  }

  const callerClient = createClient(
    SUPABASE_URL,
    SUPABASE_PUBLISHABLE_KEY,
    {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    },
  );

  const serviceClient = createClient(SUPABASE_URL, SUPABASE_SECRET_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: callerData, error: callerError } =
    await callerClient.auth.getUser();

  if (callerError || !callerData.user) {
    log('CALLER AUTH FAILED', {
      message: callerError?.message ?? 'No authenticated user.',
    });
    return json({ error: 'Invalid authentication token.' }, 401);
  }

  const adminId = callerData.user.id;

  const { data: adminProfile, error: adminProfileError } = await serviceClient
    .from('profiles')
    .select('id, full_name, email, role')
    .eq('id', adminId)
    .maybeSingle();

  if (adminProfileError) {
    log('ADMIN PROFILE LOOKUP FAILED', {
      message: adminProfileError.message,
    });
    return json({ error: adminProfileError.message }, 500);
  }

  if (String(adminProfile?.role ?? '').toUpperCase() !== 'ADMIN') {
    return json({ error: 'Admin role is required.' }, 403);
  }

  let body: Record<string, unknown>;

  try {
    body = await req.json();
  } catch (_) {
    return json({ error: 'Request body must be valid JSON.' }, 400);
  }

  let role: string;
  let email: string;
  let name: string;

  try {
    role = requiredString(body.role, 'role').toUpperCase();
    email = requiredString(body.email, 'email').toLowerCase();
    name = requiredString(body.name, 'name');
  } catch (error) {
    return json({ error: String(error) }, 400);
  }

  if (!allowedRoles.has(role)) {
    return json(
      { error: 'Only operational staff roles may be provisioned here.' },
      400,
    );
  }

  const phone = String(body.phone ?? '').trim() || null;
  const metadata = {
    full_name: name,
    name,
    phone,
    role,
  };

  log('INVITING STAFF USER', {
    admin_id: adminId,
    role,
    email,
    redirect_to: `${APP_URL}/invite`,
  });

  // The Admin client never supplies or receives the staff password. Supabase
  // sends an invitation link that establishes an authenticated session and
  // redirects the staff member to the Flutter /invite setup screen.
  const { data: createdAuth, error: createAuthError } =
    await serviceClient.auth.admin.inviteUserByEmail(email, {
      data: metadata,
      redirectTo: `${APP_URL}/invite`,
    });

  if (createAuthError || !createdAuth.user) {
    const message =
      createAuthError?.message ?? 'Could not create Auth user.';
    const duplicateEmail =
      /already registered|already exists|user already/i.test(message);

    log('AUTH INVITE FAILED', { message });

    return json(
      {
        error: duplicateEmail
          ? 'An account already exists for this email.'
          : message,
      },
      400,
    );
  }

  const userId = createdAuth.user.id;
  let resourceId: string | null = null;

  log('AUTH USER CREATED', { user_id: userId, role });

  try {
    // auth.users has an existing on_auth_user_created trigger in this project.
    // That trigger creates the profiles row. Updating it avoids the duplicate
    // profiles_pkey failure that occurred when this function inserted it again.
    const { data: updatedProfile, error: profileError } = await serviceClient
      .from('profiles')
      .update({
        full_name: name,
        email,
        phone,
        role,
      })
      .eq('id', userId)
      .select('id')
      .maybeSingle();

    if (profileError) {
      throw new Error(`Profile update failed: ${profileError.message}`);
    }

    if (!updatedProfile) {
      throw new Error(
        'Profile update failed: the auth user was created but the automatic profiles trigger did not create a matching row.',
      );
    }

    log('PROFILE UPDATED', { user_id: userId, role });

    if (role === 'DRIVER') {
      const { data, error } = await serviceClient
        .from('drivers')
        .insert({
          id: userId,
          name,
          phone,
          email,
          license_number:
            String(body.license_number ?? '').trim() || null,
          license_expiry: body.license_expiry || null,
          experience_years: Number(body.experience_years ?? 0),
          supported_categories:
            Array.isArray(body.supported_categories) &&
            body.supported_categories.length
              ? body.supported_categories
              : ['ROAD'],
          current_location:
            String(body.current_location ?? 'Central Depot').trim() ||
            'Central Depot',
          status: 'AVAILABLE',
        })
        .select('id')
        .single();

      if (error) {
        throw new Error(`Driver creation failed: ${error.message}`);
      }

      resourceId = data.id;
    }

    if (role === 'DOCTOR') {
      const { data, error } = await serviceClient
        .from('doctors')
        .insert({
          id: userId,
          name,
          phone,
          email,
          specialization:
            String(body.specialization ?? 'General Physician').trim() ||
            'General Physician',
          experience_years: Number(body.experience_years ?? 0),
          license_number:
            String(body.license_number ?? '').trim() || null,
          is_pediatric_capable: body.is_pediatric_capable === true,
          current_hospital:
            String(body.current_hospital ?? '').trim() || null,
          current_location:
            String(body.current_location ?? 'Central Hub').trim() ||
            'Central Hub',
          status: 'AVAILABLE',
        })
        .select('id')
        .single();

      if (error) {
        throw new Error(`Doctor creation failed: ${error.message}`);
      }

      resourceId = data.id;
    }

    if (role === 'CUSTOMER_CARE') {
      const { data, error } = await serviceClient
        .from('customer_care')
        .insert({
          id: userId,
          name,
          phone,
          email,
          department:
            String(
              body.department ?? '24/7 Rapid Triage & Inbound Support',
            ).trim() || '24/7 Rapid Triage & Inbound Support',
          shift: String(body.shift ?? 'MORNING').trim() || 'MORNING',
          status: 'AVAILABLE',
        })
        .select('id')
        .single();

      if (error) {
        throw new Error(`Customer Care creation failed: ${error.message}`);
      }

      resourceId = data.id;
    }

    // TEAM_LEAD currently has no confirmed dedicated resource table, so the
    // profiles row remains the canonical staff record.
    const { error: auditError } = await serviceClient
      .from('audit_logs')
      .insert({
        user_id: adminId,
        user_name:
          String(adminProfile?.full_name ?? callerData.user.email ?? 'Admin'),
        user_role: 'ADMIN',
        action: 'CREATE_STAFF',
        entity_type: role,
        new_value: JSON.stringify({
          user_id: userId,
          resource_id: resourceId,
          email,
          name,
        }),
        timestamp: new Date().toISOString(),
      });

    if (auditError) {
      throw new Error(`Audit logging failed: ${auditError.message}`);
    }

    log('STAFF PROVISIONING COMPLETED', {
      user_id: userId,
      resource_id: resourceId,
      role,
      email,
    });
  } catch (error) {
    log('STAFF PROVISIONING FAILED', {
      user_id: userId,
      role,
      message: String(error),
    });

    if (role === 'DRIVER') {
      await serviceClient.from('drivers').delete().eq('id', userId);
    }

    if (role === 'DOCTOR') {
      await serviceClient.from('doctors').delete().eq('id', userId);
    }

    if (role === 'CUSTOMER_CARE') {
      await serviceClient.from('customer_care').delete().eq('id', userId);
    }

    // Do not delete profiles separately. The existing auth trigger owns the
    // initial profile creation, and deleting the Auth user is the rollback
    // boundary for this transaction-like workflow.
    await serviceClient.auth.admin.deleteUser(userId);

    log('AUTH USER ROLLBACK COMPLETED', { user_id: userId });

    return json({ error: String(error) }, 400);
  }

  return json(
    {
      success: true,
      user_id: userId,
      resource_id: resourceId,
      role,
      email,
      invite_redirect: `${APP_URL}/invite`,
    },
    201,
  );
});
