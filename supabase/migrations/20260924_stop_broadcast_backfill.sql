-- Already applied to Supabase (stop_broadcast_backfill_for_new_users).
-- New accounts must only see notifications created after they signed up.
-- This supersedes the "New profile -> gets the latest 5 broadcasts" behaviour
-- from 20260921_broadcast_catch_up.sql.
drop trigger if exists profiles_backfill_broadcasts on public.profiles;

-- Remove old broadcast copies that were backfilled into accounts created after the broadcast was sent.
delete from public.notifications n
using auth.users u
where n.user_id = u.id
  and n.type = 'broadcast'
  and n.created_at < u.created_at;
