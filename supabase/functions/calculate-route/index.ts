import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const PUBLISHABLE_KEY =
  Deno.env.get('SUPABASE_PUBLISHABLE_KEY') ??
  Deno.env.get('SUPABASE_ANON_KEY') ??
  '';
const NOMINATIM_URL = 'https://nominatim.openstreetmap.org/search';
const OSRM_URL = 'https://router.project-osrm.org/route/v1/driving';

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function asNumber(value: unknown): number | null {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

async function geocodeAddress(address: string): Promise<[number, number]> {
  const query = address.trim();
  if (!query) throw new Error('An address is required for route calculation.');

  const url = new URL(NOMINATIM_URL);
  url.searchParams.set('format', 'jsonv2');
  url.searchParams.set('limit', '1');
  url.searchParams.set('countrycodes', 'in');
  url.searchParams.set('q', query);

  const response = await fetch(url, {
    headers: {
      Accept: 'application/json',
      'User-Agent': 'AeroMed-AmbulanceFirst/1.0 (route-calculation)',
    },
  });

  if (!response.ok) {
    throw new Error(`Address lookup failed (${response.status}).`);
  }

  const rows = await response.json();
  if (!Array.isArray(rows) || rows.length === 0) {
    throw new Error(`Could not find coordinates for: ${query}`);
  }

  const lat = asNumber(rows[0]?.lat);
  const lon = asNumber(rows[0]?.lon);
  if (lat == null || lon == null) {
    throw new Error(`Address lookup returned invalid coordinates for: ${query}`);
  }
  return [lat, lon];
}

async function calculateOsrmRoute(
  pickupLat: number,
  pickupLng: number,
  destinationLat: number,
  destinationLng: number,
  includeGeometry: boolean,
) {
  const overview = includeGeometry ? 'full' : 'false';
  const url = `${OSRM_URL}/${pickupLng},${pickupLat};${destinationLng},${destinationLat}?overview=${overview}&geometries=geojson&steps=false`;
  const response = await fetch(url, {
    headers: { Accept: 'application/json' },
  });
  if (!response.ok) throw new Error(`Road routing failed (${response.status}).`);

  const body = await response.json();
  if (body?.code !== 'Ok' || !Array.isArray(body?.routes) || body.routes.length === 0) {
    throw new Error(body?.message ?? 'No drivable route was found between the locations.');
  }

  const route = body.routes[0];
  const distance = asNumber(route.distance);
  const duration = asNumber(route.duration);
  if (distance == null || distance < 0 || duration == null || duration < 0) {
    throw new Error('Routing service returned an invalid distance or duration.');
  }

  return {
    distanceMeters: Math.round(distance),
    durationSeconds: Math.round(duration),
    provider: 'OSRM/OSM',
    geometry: route.geometry ?? null,
  };
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'Method not allowed.' }, 405);
  if (!SUPABASE_URL || !PUBLISHABLE_KEY) {
    return json({ error: 'Supabase function authentication is not configured.' }, 500);
  }

  const authorization = req.headers.get('Authorization');
  if (!authorization?.startsWith('Bearer ')) return json({ error: 'Authentication is required.' }, 401);

  const client = createClient(SUPABASE_URL, PUBLISHABLE_KEY, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: authData, error: authError } = await client.auth.getUser();
  if (authError || !authData.user) return json({ error: 'Invalid authentication token.' }, 401);

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch (_) {
    return json({ error: 'Request body must be valid JSON.' }, 400);
  }

  try {
    const pickupAddress = String(body.pickup_address ?? '').trim();
    const destinationAddress = String(body.destination_address ?? '').trim();
    if (!pickupAddress || !destinationAddress) {
      throw new Error('Pickup and destination addresses are required.');
    }

    let pickupLat = asNumber(body.pickup_lat);
    let pickupLng = asNumber(body.pickup_lng);
    let destinationLat = asNumber(body.destination_lat);
    let destinationLng = asNumber(body.destination_lng);

    if (pickupLat == null || pickupLng == null) {
      [pickupLat, pickupLng] = await geocodeAddress(pickupAddress);
    }
    if (destinationLat == null || destinationLng == null) {
      [destinationLat, destinationLng] = await geocodeAddress(destinationAddress);
    }

    const route = await calculateOsrmRoute(
      pickupLat,
      pickupLng,
      destinationLat,
      destinationLng,
      body.include_geometry === true,
    );

    return json({
      pickup_lat: pickupLat,
      pickup_lng: pickupLng,
      destination_lat: destinationLat,
      destination_lng: destinationLng,
      distance_meters: route.distanceMeters,
      duration_seconds: route.durationSeconds,
      distance_km: Number((route.distanceMeters / 1000).toFixed(2)),
      duration_mins: Math.ceil(route.durationSeconds / 60),
      provider: route.provider,
      route_geometry: body.include_geometry === true ? route.geometry : null,
      calculated_at: new Date().toISOString(),
    });
  } catch (error) {
    console.error('[calculate-route]', error);
    return json(
      { error: error instanceof Error ? error.message : 'Route calculation failed.' },
      400,
    );
  }
});
