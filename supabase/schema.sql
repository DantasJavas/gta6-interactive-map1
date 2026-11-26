-- JavasMapGTAVI: progresso privado por conta Supabase
-- Execute este arquivo uma única vez no SQL Editor do seu projeto Supabase.

create table if not exists public.player_progress (
  user_id uuid primary key references auth.users(id) on delete cascade,
  found_ids text[] not null default '{}',
  chapter_availability jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  constraint chapter_availability_is_object
    check (jsonb_typeof(chapter_availability) = 'object')
);

alter table public.player_progress enable row level security;

-- Cada conta só pode ler e alterar a própria linha.
drop policy if exists "Players can read own progress" on public.player_progress;
create policy "Players can read own progress"
  on public.player_progress for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Players can insert own progress" on public.player_progress;
create policy "Players can insert own progress"
  on public.player_progress for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Players can update own progress" on public.player_progress;
create policy "Players can update own progress"
  on public.player_progress for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

grant select, insert, update on public.player_progress to authenticated;

-- Permite receber atualizações em tempo real nos outros dispositivos da mesma conta.
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'player_progress'
  ) then
    alter publication supabase_realtime add table public.player_progress;
  end if;
end
$$;
