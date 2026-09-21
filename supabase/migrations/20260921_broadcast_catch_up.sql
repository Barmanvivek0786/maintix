-- Broadcast catch-up + OneSignal dashboard import (already applied to Supabase).
--
-- * admin_broadcasts.onesignal_id: broadcasts sent from the OneSignal dashboard
--   are imported every 10 minutes by the sync-onesignal-messages Edge Function
--   (pg_cron job maintix-sync-onesignal-messages) and fanned out into every
--   user's in-app notification list (no second push).
-- * New profile -> gets the latest 5 broadcasts in their list (no push).
-- To stop a broadcast from showing to new users: delete its row from
-- admin_broadcasts (and the copies from notifications if wanted).

alter table public.admin_broadcasts add column if not exists onesignal_id text;
alter table public.admin_broadcasts add constraint admin_broadcasts_onesignal_id_key unique (onesignal_id);

-- fan_out_onesignal_broadcast(): after insert on admin_broadcasts when onesignal_id is not null
--   inserts a 'broadcast' notification row for every profile.
-- backfill_broadcasts_for_new_profile(): after insert on profiles
--   inserts the latest 5 admin_broadcasts as 'broadcast' rows for the new user.
-- sync_onesignal_messages_cron(): pg_net call to the sync Edge Function,
--   scheduled '*/10 * * * *'.
-- (Full function bodies live in the Supabase project migrations:
--  broadcast_catch_up_and_onesignal_import, schedule_onesignal_message_sync.)
