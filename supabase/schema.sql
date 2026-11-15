create table if not exists public.workouts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null check (length(btrim(title)) > 0),
  session_date date not null default current_date,
  created_at timestamptz not null default now()
);

create index if not exists workouts_user_date_idx
  on public.workouts (user_id, session_date desc);

create table if not exists public.exercises (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references auth.users (id) on delete cascade,
  name text not null check (length(btrim(name)) > 0),
  muscle_groups text[] not null default '{}'::text[],
  created_at timestamptz not null default now()
);

create table if not exists public.workout_exercises (
  workout_id uuid not null references public.workouts (id) on delete cascade,
  exercise_id uuid not null references public.exercises (id) on delete restrict,
  order_index integer not null check (order_index >= 1),
  notes text not null default '',
  primary key (workout_id, exercise_id),
  unique (workout_id, order_index)
);

alter table public.workout_exercises
  add column if not exists notes text not null default '';

create table if not exists public.workout_sets (
  workout_id uuid not null,
  exercise_id uuid not null,
  set_number integer not null check (set_number >= 1),
  weight_kg numeric(8, 2) not null default 0 check (weight_kg >= 0),
  reps integer not null default 0 check (reps >= 0),
  completed boolean not null default false,
  primary key (workout_id, exercise_id, set_number),
  foreign key (workout_id, exercise_id)
    references public.workout_exercises (workout_id, exercise_id)
    on delete cascade
);

create index if not exists workout_sets_exercise_workout_idx
  on public.workout_sets (exercise_id, workout_id);

alter table public.workouts enable row level security;
alter table public.exercises enable row level security;
alter table public.workout_exercises enable row level security;
alter table public.workout_sets enable row level security;

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.workouts to authenticated;
grant select, insert, update, delete on public.exercises to authenticated;
grant select, insert, update, delete on public.workout_exercises to authenticated;
grant select, insert, update, delete on public.workout_sets to authenticated;

drop policy if exists workouts_select_own on public.workouts;
create policy workouts_select_own
  on public.workouts for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists workouts_insert_own on public.workouts;
create policy workouts_insert_own
  on public.workouts for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists workouts_update_own on public.workouts;
create policy workouts_update_own
  on public.workouts for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists workouts_delete_own on public.workouts;
create policy workouts_delete_own
  on public.workouts for delete to authenticated
  using (auth.uid() = user_id);

drop policy if exists exercises_select_available on public.exercises;
create policy exercises_select_available
  on public.exercises for select to authenticated
  using (owner_id is null or auth.uid() = owner_id);

drop policy if exists exercises_insert_own on public.exercises;
create policy exercises_insert_own
  on public.exercises for insert to authenticated
  with check (auth.uid() = owner_id);

drop policy if exists exercises_update_own on public.exercises;
create policy exercises_update_own
  on public.exercises for update to authenticated
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

drop policy if exists exercises_delete_own on public.exercises;
create policy exercises_delete_own
  on public.exercises for delete to authenticated
  using (auth.uid() = owner_id);

drop policy if exists workout_exercises_select_own on public.workout_exercises;
create policy workout_exercises_select_own
  on public.workout_exercises for select to authenticated
  using (
    exists (
      select 1
      from public.workouts
      where workouts.id = workout_exercises.workout_id
        and workouts.user_id = auth.uid()
    )
    and exists (
      select 1
      from public.exercises
      where exercises.id = workout_exercises.exercise_id
    )
  );

drop policy if exists workout_exercises_insert_own on public.workout_exercises;
create policy workout_exercises_insert_own
  on public.workout_exercises for insert to authenticated
  with check (
    exists (
      select 1
      from public.workouts
      where workouts.id = workout_exercises.workout_id
        and workouts.user_id = auth.uid()
    )
    and exists (
      select 1
      from public.exercises
      where exercises.id = workout_exercises.exercise_id
    )
  );

drop policy if exists workout_exercises_update_own on public.workout_exercises;
create policy workout_exercises_update_own
  on public.workout_exercises for update to authenticated
  using (
    exists (
      select 1
      from public.workouts
      where workouts.id = workout_exercises.workout_id
        and workouts.user_id = auth.uid()
    )
    and exists (
      select 1
      from public.exercises
      where exercises.id = workout_exercises.exercise_id
    )
  )
  with check (
    exists (
      select 1
      from public.workouts
      where workouts.id = workout_exercises.workout_id
        and workouts.user_id = auth.uid()
    )
    and exists (
      select 1
      from public.exercises
      where exercises.id = workout_exercises.exercise_id
    )
  );

drop policy if exists workout_exercises_delete_own on public.workout_exercises;
create policy workout_exercises_delete_own
  on public.workout_exercises for delete to authenticated
  using (
    exists (
      select 1
      from public.workouts
      where workouts.id = workout_exercises.workout_id
        and workouts.user_id = auth.uid()
    )
  );

drop policy if exists workout_sets_select_own on public.workout_sets;
create policy workout_sets_select_own
  on public.workout_sets for select to authenticated
  using (
    exists (
      select 1
      from public.workouts
      where workouts.id = workout_sets.workout_id
        and workouts.user_id = auth.uid()
    )
  );

drop policy if exists workout_sets_insert_own on public.workout_sets;
create policy workout_sets_insert_own
  on public.workout_sets for insert to authenticated
  with check (
    exists (
      select 1
      from public.workouts
      where workouts.id = workout_sets.workout_id
        and workouts.user_id = auth.uid()
    )
  );

drop policy if exists workout_sets_update_own on public.workout_sets;
create policy workout_sets_update_own
  on public.workout_sets for update to authenticated
  using (
    exists (
      select 1
      from public.workouts
      where workouts.id = workout_sets.workout_id
        and workouts.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from public.workouts
      where workouts.id = workout_sets.workout_id
        and workouts.user_id = auth.uid()
    )
  );

drop policy if exists workout_sets_delete_own on public.workout_sets;
create policy workout_sets_delete_own
  on public.workout_sets for delete to authenticated
  using (
    exists (
      select 1
      from public.workouts
      where workouts.id = workout_sets.workout_id
        and workouts.user_id = auth.uid()
    )
  );

create or replace view public.workout_muscle_groups
with (security_invoker = true)
as
select
  workouts.id as workout_id,
  coalesce(
    array_agg(distinct muscles.muscle_group order by muscles.muscle_group)
      filter (where muscles.muscle_group is not null),
    '{}'::text[]
  ) as muscle_groups
from public.workouts
left join public.workout_exercises
  on workout_exercises.workout_id = workouts.id
left join public.exercises
  on exercises.id = workout_exercises.exercise_id
left join lateral unnest(exercises.muscle_groups) as muscles(muscle_group)
  on true
group by workouts.id;

grant select on public.workout_muscle_groups to authenticated;

drop function if exists public.create_workout(text, date, uuid[]);

create or replace function public.create_workout(
  p_title text,
  p_session_date date default current_date,
  p_exercise_ids uuid[] default '{}'::uuid[],
  p_exercise_details jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_workout_id uuid;
  v_available_count integer;
  v_unique_count integer;
  v_details_count integer;
begin
  if v_user_id is null then
    raise exception 'Connecte-toi pour enregistrer une séance.';
  end if;

  if nullif(btrim(p_title), '') is null then
    raise exception 'Le titre de la séance ne peut pas être vide.';
  end if;

  p_exercise_ids := coalesce(p_exercise_ids, '{}'::uuid[]);
  p_exercise_details := coalesce(p_exercise_details, '[]'::jsonb);

  if jsonb_typeof(p_exercise_details) <> 'array' then
    raise exception 'Les informations des exercices sont invalides.';
  end if;

  select count(*)
    into v_details_count
  from jsonb_array_elements(p_exercise_details);

  if v_details_count <> cardinality(p_exercise_ids) then
    raise exception 'Les informations des exercices ne correspondent pas à la séance.';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_exercise_details) with ordinality
      as details(value, exercise_order)
    where jsonb_typeof(details.value) <> 'object'
      or jsonb_typeof(details.value -> 'sets') is distinct from 'array'
  ) then
    raise exception 'Les séries d’un exercice sont invalides.';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_exercise_details) with ordinality
      as details(value, exercise_order)
    join unnest(p_exercise_ids) with ordinality
      as requested(exercise_id, exercise_order)
      using (exercise_order)
    where details.value ->> 'exercise_id' is distinct from requested.exercise_id::text
  ) then
    raise exception 'Les informations des exercices sont dans un ordre invalide.';
  end if;

  select count(distinct requested.exercise_id)
    into v_unique_count
  from unnest(p_exercise_ids) as requested(exercise_id);

  if v_unique_count <> cardinality(p_exercise_ids) then
    raise exception 'Un exercice ne peut être ajouté qu’une fois à la séance.';
  end if;

  if cardinality(p_exercise_ids) > 0 then
    select count(*)
      into v_available_count
    from public.exercises
    where id = any(p_exercise_ids);

    if v_available_count <> cardinality(p_exercise_ids) then
      raise exception 'Un ou plusieurs exercices ne sont pas accessibles.';
    end if;
  end if;

  insert into public.workouts (user_id, title, session_date)
  values (v_user_id, btrim(p_title), coalesce(p_session_date, current_date))
  returning id into v_workout_id;

  insert into public.workout_exercises (workout_id, exercise_id, order_index, notes)
  select
    v_workout_id,
    requested.exercise_id,
    requested.exercise_order::integer,
    coalesce(details.value ->> 'notes', '')
  from jsonb_array_elements(p_exercise_details) with ordinality
    as details(value, exercise_order)
  join unnest(p_exercise_ids) with ordinality
    as requested(exercise_id, exercise_order)
    using (exercise_order);

  insert into public.workout_sets (
    workout_id,
    exercise_id,
    set_number,
    weight_kg,
    reps,
    completed
  )
  select
    v_workout_id,
    requested.exercise_id,
    set_data.set_order::integer,
    coalesce((set_data.value ->> 'weight_kg')::numeric, 0),
    coalesce((set_data.value ->> 'reps')::integer, 0),
    coalesce((set_data.value ->> 'completed')::boolean, false)
  from jsonb_array_elements(p_exercise_details) with ordinality
    as details(value, exercise_order)
  join unnest(p_exercise_ids) with ordinality
    as requested(exercise_id, exercise_order)
    using (exercise_order)
  cross join lateral jsonb_array_elements(details.value -> 'sets') with ordinality
    as set_data(value, set_order);

  return v_workout_id;
end;
$$;

revoke all on function public.create_workout(text, date, uuid[], jsonb) from public, anon;
grant execute on function public.create_workout(text, date, uuid[], jsonb) to authenticated;
