-- Migration 0012: task categories + recurring task support

create table public.task_categories (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id) on delete cascade,
  name        text not null,
  emoji       text not null default '',
  slug        text unique,
  is_default  boolean not null default false,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now(),
  constraint task_categories_name_length check (char_length(trim(name)) between 1 and 80),
  constraint task_categories_emoji_length check (char_length(emoji) between 1 and 16),
  constraint task_categories_default_shape check (
    (is_default = true and user_id is null and slug is not null)
    or (is_default = false and user_id is not null)
  )
);

create unique index task_categories_user_name_idx
  on public.task_categories(user_id, lower(name))
  where user_id is not null;

create index task_categories_defaults_idx
  on public.task_categories(is_default, name);

create index task_categories_user_idx
  on public.task_categories(user_id);

alter table public.task_categories enable row level security;

create policy "Users can view own or default task categories"
  on public.task_categories for select
  using (is_default = true or auth.uid() = user_id);

create policy "Users can insert own task categories"
  on public.task_categories for insert
  with check (auth.uid() = user_id and is_default = false);

create policy "Users can update own task categories"
  on public.task_categories for update
  using (auth.uid() = user_id and is_default = false)
  with check (auth.uid() = user_id and is_default = false);

create policy "Users can delete own task categories"
  on public.task_categories for delete
  using (auth.uid() = user_id and is_default = false);

create trigger set_task_categories_updated_at
  before update on public.task_categories
  for each row execute function public.set_updated_at();

insert into public.task_categories (name, emoji, slug, is_default)
values
  ('Work', '💼', 'work', true),
  ('Relationship', '❤️', 'relationship', true),
  ('Goals', '🎯', 'goals', true),
  ('Social', '🥂', 'social', true),
  ('Health', '💪', 'health', true);

alter table public.tasks
  add column category_id uuid references public.task_categories(id) on delete set null,
  add column repeat_frequency text check (repeat_frequency in ('daily', 'weekly', 'monthly', 'yearly')),
  add column series_id uuid;

create index tasks_user_category_idx on public.tasks(user_id, category_id);
create index tasks_user_series_idx on public.tasks(user_id, series_id);

create unique index tasks_series_due_date_uidx
  on public.tasks(series_id, due_date)
  where series_id is not null and due_date is not null;

create or replace function public.complete_recurring_task(
  p_task_id uuid,
  p_user_id uuid,
  p_completed_at timestamptz default now()
)
returns table(current_task_id uuid, next_task_id uuid) as $$
declare
  v_task public.tasks%rowtype;
  v_next_due_date timestamptz;
  v_next_task_id uuid;
  v_series_id uuid;
begin
  select *
    into v_task
  from public.tasks
  where id = p_task_id
    and user_id = p_user_id
  for update;

  if not found then
    return;
  end if;

  v_series_id := coalesce(v_task.series_id, gen_random_uuid());

  update public.tasks
     set is_completed = true,
         completed_at = coalesce(p_completed_at, now()),
         series_id = v_series_id,
         updated_at = now()
   where id = v_task.id;

  current_task_id := v_task.id;

  if v_task.repeat_frequency is null or v_task.due_date is null then
    next_task_id := null;
    return next;
  end if;

  v_next_due_date := case v_task.repeat_frequency
    when 'daily' then v_task.due_date + interval '1 day'
    when 'weekly' then v_task.due_date + interval '1 week'
    when 'monthly' then v_task.due_date + interval '1 month'
    when 'yearly' then v_task.due_date + interval '1 year'
    else null
  end;

  if v_next_due_date is null then
    next_task_id := null;
    return next;
  end if;

  insert into public.tasks (
    user_id,
    title,
    note,
    is_completed,
    priority,
    due_date,
    completed_at,
    category_id,
    repeat_frequency,
    series_id
  )
  values (
    v_task.user_id,
    v_task.title,
    coalesce(v_task.note, ''),
    false,
    v_task.priority,
    v_next_due_date,
    null,
    v_task.category_id,
    v_task.repeat_frequency,
    v_series_id
  )
  on conflict (series_id, due_date)
    where series_id is not null and due_date is not null
  do nothing
  returning id into v_next_task_id;

  if v_next_task_id is null then
    select id
      into v_next_task_id
    from public.tasks
    where series_id = v_series_id
      and due_date = v_next_due_date
      and user_id = p_user_id
    limit 1;
  end if;

  next_task_id := v_next_task_id;
  return next;
end;
$$ language plpgsql;