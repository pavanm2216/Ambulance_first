-- Enable persisted route metadata in the Customer booking creation RPC after real route calculation.
-- IMPORTANT: jsonb_populate_record() does NOT apply column defaults for
-- omitted JSON keys. Therefore every NOT NULL bookings column that has no
-- server-side trigger/default applied by the record population must be
-- explicitly initialized here.
-- Live public.bookings NOT NULL columns are:
--   id, status, customer_care_verified, quotation_revision,
--   cc_check_patient_condition, cc_check_oxygen_therapy,
--   cc_check_ventilator_loaded, cc_check_doctor_designated,
--   cc_check_receiving_bed_secured, cc_check_route_priority_cleared.
-- Do NOT add legacy customer_verified; that column does not exist.

begin;

create or replace function public.create_customer_booking(p_booking jsonb)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id text;
  v_payload jsonb;
begin
  if auth.uid() is null or public.app_role() <> 'CUSTOMER' then
    raise exception 'Only authenticated CUSTOMER users may create bookings';
  end if;

  v_id := nullif(trim(p_booking->>'id'), '');
  if v_id is null then
    raise exception 'Booking id is required';
  end if;

  -- Strip all client-controlled workflow/assignment/quotation fields.
  -- The Customer app may provide normal booking/request fields, but it must
  -- not set verification, assignment, quotation, or trip-state fields.
  v_payload := p_booking
    - ARRAY[
      'status','customer_id','created_at','updated_at',
      'customer_verified',
      'customer_care_verified','customer_care_verified_at',
      'customer_care_verification_notes',
      'cc_verified_by_id','cc_verified_by_name','cc_verified_at',
      'cc_call_status','cc_call_duration_secs','cc_notes','cc_priority',
      'cc_patient_condition_confirmed','cc_medical_req_confirmed',
      'cc_location_confirmed','cc_datetime_confirmed',
      'assigned_ambulance_id','assigned_driver_id','assigned_emt_id',
      'assigned_doctor_id','assigned_by_tl_id','assigned_by_tl_name','assigned_at',
      'driver_name','driver_phone','ambulance_vehicle_number','ambulance_name',
      'doctor_name','emt_name',
      'quotation_id','quotation_status','quotation_prepared_by_id',
      'quotation_prepared_by_name','quotation_prepared_at','quotation_sent_at',
      'quotation_responded_at','quotation_rejection_reason','quotation_revision',
      'q_base_charge','q_distance_charge','q_doctor_charge','q_emt_charge',
      'q_oxygen_charge','q_icu_charge','q_ventilator_charge',
      'q_pediatric_icu_charge','q_equipment_charge','q_attendant_charge',
      'q_air_charges','q_railway_charges','q_additional_charges',
      'q_subtotal','q_discount','q_tax_percent','q_tax_amount','q_final_amount',
      'q_payment_terms','q_valid_until','q_notes',
      'trip_started_at','patient_picked_up_at','in_transit_at','arrived_at',
      'completed_at','geo_lat','geo_lng','geo_speed_kmh','geo_heading',
      'geo_eta_mins','geo_last_ping',
      'customer_accepted_at','customer_rejected_at',
      'driver_accepted_at','driver_rejected_at','driver_rejection_reason',
      'pickup_arrived_at','patient_onboard_at','drop_arrived_at',
      'trip_completed_at','cancellation_reason','cancelled_at','cancelled_by_id',
      'cc_check_patient_condition','cc_check_oxygen_therapy',
      'cc_check_ventilator_loaded','cc_check_doctor_designated',
      'cc_check_receiving_bed_secured','cc_check_route_priority_cleared',
    ]
    || jsonb_build_object(
      'customer_id', auth.uid(),
      'status', 'NEW',
      'customer_care_verified', false,
      'quotation_revision', 0,
      'cc_check_patient_condition', false,
      'cc_check_oxygen_therapy', false,
      'cc_check_ventilator_loaded', false,
      'cc_check_doctor_designated', false,
      'cc_check_receiving_bed_secured', false,
      'cc_check_route_priority_cleared', false
    );

  insert into public.bookings
  select (jsonb_populate_record(null::public.bookings, v_payload)).*;

  return v_id;
end;
$$;

revoke all on function public.create_customer_booking(jsonb) from public;
grant execute on function public.create_customer_booking(jsonb) to authenticated;

commit;
