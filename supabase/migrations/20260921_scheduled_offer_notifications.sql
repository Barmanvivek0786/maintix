-- Scheduled offer notifications (already applied to the Supabase project).
-- Sends one personalised offer per user 3x a day: 10:00, 14:00, 18:00 IST
-- (4 hours apart, quiet at night). Each inserted row triggers the push via the
-- notifications DB trigger -> send-push-notification -> OneSignal.
--
-- New users (no booking yet): WEL100 (Rs 100 off first booking), 3-tank Rs 500
-- offer, wallet coins, cleaning reminder.
-- Existing users: 3-tank Rs 500 offer, wallet coins, review reward, reminder.
-- Skips a user who got an offer/coupon notification in the last 3 hours.

create extension if not exists pg_cron;

create or replace function public.send_scheduled_offers(
  p_slot integer default 0,
  p_only_user uuid default null,
  p_force boolean default false
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  r record;
  seq bigint;
  pick integer;
  v_type text;
  v_title text;
  v_body text;
  sent integer := 0;
begin
  seq := (extract(doy from (now() at time zone 'Asia/Kolkata'))::bigint * 3) + p_slot;

  for r in
    select
      p.id as user_id,
      exists (select 1 from public.bookings b where b.user_id = p.id) as has_booking,
      coalesce((select c.balance from public.user_coins c where c.user_id = p.id), 0) as coins,
      (select max(b.created_at) from public.bookings b where b.user_id = p.id) as last_booking,
      (select max(rv.created_at) from public.reviews rv where rv.user_id = p.id) as last_review
    from public.profiles p
    where (p_only_user is null or p.id = p_only_user)
      and (
        p_force
        or not exists (
          select 1 from public.notifications n
          where n.user_id = p.id
            and n.type in ('offer', 'coupon')
            and n.created_at > now() - interval '3 hours'
        )
      )
  loop
    pick := ((seq + abs(hashtext(r.user_id::text)::bigint)) % 4)::integer;

    v_type  := 'offer';
    v_title := '🎉 3 tank book karein, ₹500 flat off!';
    v_body  := '3 ya usse zyada tank ek saath book karne par ₹500 ki flat chhoot apne aap mil jaati hai. Abhi apna slot book karein.';

    if not r.has_booking then
      if pick = 0 or (pick = 2 and r.coins <= 0) then
        v_title := '🎁 Pehli booking par ₹100 off!';
        v_body  := 'Welcome offer: apni pehli water tank cleaning par ₹100 ki chhoot paayein. Checkout par code WEL100 lagayein.';
      elsif pick = 2 then
        v_title := format('🪙 Aapke wallet mein %s coins hain', r.coins);
        v_body  := 'Booking ke waqt wallet coins use karke aur bachat karein (ek booking par max 50 coins).';
      elsif pick = 3 then
        v_title := '🚰 Tank saaf karwane ka sahi time';
        v_body  := 'Saaf tank ka matlab saaf aur surakshit paani. Professional tank cleaning ka apna slot aaj hi book karein.';
      end if;
    else
      if pick = 1 and r.coins > 0 then
        v_title := format('🪙 Aapke wallet mein %s coins hain', r.coins);
        v_body  := 'Agli booking par wallet coins use karke aur bachat karein (ek booking par max 50 coins).';
      elsif pick = 2 and (r.last_review is null or r.last_review < r.last_booking) then
        v_type  := 'reward';
        v_title := '⭐ Review likhein, 10 coins paayein';
        v_body  := 'Apni service ka review likhkar 10 coins kamayein aur agli booking par use karein.';
      elsif pick >= 2 then
        v_title := '🚰 Tank dobara saaf karwane ka time?';
        v_body  := 'Regular cleaning se paani saaf rehta hai. Apna agla slot aaj hi book karein.';
      end if;
    end if;

    insert into public.notifications (user_id, title, body, type)
    values (r.user_id, v_title, v_body, v_type);
    sent := sent + 1;
  end loop;

  return sent;
end;
$$;

revoke all on function public.send_scheduled_offers(integer, uuid, boolean) from public, anon, authenticated;

select cron.schedule('maintix-offers-10am', '30 4 * * *',  $$select public.send_scheduled_offers(0);$$);
select cron.schedule('maintix-offers-2pm',  '30 8 * * *',  $$select public.send_scheduled_offers(1);$$);
select cron.schedule('maintix-offers-6pm',  '30 12 * * *', $$select public.send_scheduled_offers(2);$$);
select cron.schedule('maintix-offers-cleanup', '0 21 * * *',
  $$delete from public.notifications where type = 'offer' and created_at < now() - interval '14 days';$$);
