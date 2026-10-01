begin;

alter function public.preview_booking_quotation(text) owner to postgres;
revoke all on function public.preview_booking_quotation(text) from public;
grant execute on function public.preview_booking_quotation(text) to authenticated;

alter function public.prepare_booking_quotation(text, numeric, text, numeric) owner to postgres;
revoke all on function public.prepare_booking_quotation(text, numeric, text, numeric) from public;
grant execute on function public.prepare_booking_quotation(text, numeric, text, numeric) to authenticated;

notify pgrst, 'reload schema';
commit;