-- AZOX ESPORT — schéma initial Supabase / PostgreSQL
-- À exécuter dans Supabase > SQL Editor.
-- Aucune statistique n'est préremplie. Seuls les trois profils de base sont créés.

create extension if not exists pgcrypto;

create table if not exists public.azox_players (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  display_name text not null,
  epic_name text,
  team_role text,
  platform text,
  public_link text,
  bio text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.azox_results (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references public.azox_players(id) on delete cascade,
  event_name text not null,
  event_date date,
  placement integer check (placement is null or placement > 0),
  points numeric(10,2) check (points is null or points >= 0),
  eliminations integer check (eliminations is null or eliminations >= 0),
  created_at timestamptz not null default now()
);

create index if not exists azox_results_player_id_idx on public.azox_results(player_id);
create index if not exists azox_results_event_date_idx on public.azox_results(event_date);

insert into public.azox_players (slug, display_name)
values ('rome', 'Rome'), ('lucky', 'Lucky'), ('sacha', 'Sacha')
on conflict (slug) do nothing;

-- Classement calculé depuis les résultats réellement saisis.
create or replace view public.azox_ranking
with (security_invoker = true) as
with totals as (
  select
    p.id as player_id,
    p.display_name,
    count(r.id) filter (where r.points is not null) as scored_events,
    sum(r.points) as total_points
  from public.azox_players p
  left join public.azox_results r on r.player_id = p.id
  group by p.id, p.display_name
),
ranked as (
  select *,
    case when total_points is null then null
         else rank() over (order by total_points desc nulls last)
    end as internal_rank
  from totals
)
select player_id, display_name, scored_events, total_points, internal_rank
from ranked;

-- Lecture publique des profils et résultats.
alter table public.azox_players enable row level security;
alter table public.azox_results enable row level security;

drop policy if exists "AZOX public can read players" on public.azox_players;
create policy "AZOX public can read players"
on public.azox_players for select
to anon, authenticated
using (true);

drop policy if exists "AZOX public can read results" on public.azox_results;
create policy "AZOX public can read results"
on public.azox_results for select
to anon, authenticated
using (true);

-- Écriture réservée à un compte dont le rôle app_metadata.role vaut azox_admin.
-- Attribuer ce rôle depuis un environnement serveur / Supabase Dashboard,
-- jamais depuis le navigateur public.
drop policy if exists "AZOX admins can insert players" on public.azox_players;
create policy "AZOX admins can insert players"
on public.azox_players for insert
to authenticated
with check ((auth.jwt() -> 'app_metadata' ->> 'role') = 'azox_admin');

drop policy if exists "AZOX admins can update players" on public.azox_players;
create policy "AZOX admins can update players"
on public.azox_players for update
to authenticated
using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'azox_admin')
with check ((auth.jwt() -> 'app_metadata' ->> 'role') = 'azox_admin');

drop policy if exists "AZOX admins can delete players" on public.azox_players;
create policy "AZOX admins can delete players"
on public.azox_players for delete
to authenticated
using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'azox_admin');

drop policy if exists "AZOX admins can insert results" on public.azox_results;
create policy "AZOX admins can insert results"
on public.azox_results for insert
to authenticated
with check ((auth.jwt() -> 'app_metadata' ->> 'role') = 'azox_admin');

drop policy if exists "AZOX admins can update results" on public.azox_results;
create policy "AZOX admins can update results"
on public.azox_results for update
to authenticated
using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'azox_admin')
with check ((auth.jwt() -> 'app_metadata' ->> 'role') = 'azox_admin');

drop policy if exists "AZOX admins can delete results" on public.azox_results;
create policy "AZOX admins can delete results"
on public.azox_results for delete
to authenticated
using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'azox_admin');
