-- Create availabilities table
create table public.availabilities (
    id uuid default uuid_generate_v4() primary key,
    goalkeeper_id uuid references public.users(id) on delete cascade not null,
    day date not null,
    start_time time not null,
    end_time time not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create indexes for better performance
create index availabilities_goalkeeper_id_idx on public.availabilities(goalkeeper_id);
create index availabilities_day_idx on public.availabilities(day);
create index availabilities_goalkeeper_day_idx on public.availabilities(goalkeeper_id, day);

-- Add RLS (Row Level Security) policies
alter table public.availabilities enable row level security;

-- Policy: Users can read all availabilities (for booking purposes)
create policy "Availabilities are viewable by everyone" 
    on public.availabilities for select 
    using (true);

-- Policy: Only the goalkeeper can insert their own availability
create policy "Goalkeepers can insert their own availability" 
    on public.availabilities for insert 
    with check (auth.uid() = goalkeeper_id);

-- Policy: Only the goalkeeper can update their own availability
create policy "Goalkeepers can update their own availability" 
    on public.availabilities for update 
    using (auth.uid() = goalkeeper_id);

-- Policy: Only the goalkeeper can delete their own availability
create policy "Goalkeepers can delete their own availability" 
    on public.availabilities for delete 
    using (auth.uid() = goalkeeper_id);

-- Add a constraint to ensure start_time is before end_time
alter table public.availabilities 
add constraint availabilities_time_order_check 
check (start_time < end_time);

-- Add a constraint to prevent overlapping time slots for the same goalkeeper on the same day
create unique index availabilities_no_overlap_idx on public.availabilities (
    goalkeeper_id, 
    day, 
    tsrange(
        (day + start_time)::timestamp, 
        (day + end_time)::timestamp, 
        '[)'
    )
);

-- Add comments for documentation
comment on table public.availabilities is 'Stores goalkeeper availability time slots';
comment on column public.availabilities.goalkeeper_id is 'Reference to the goalkeeper user';
comment on column public.availabilities.day is 'The date of availability';
comment on column public.availabilities.start_time is 'Start time of availability';
comment on column public.availabilities.end_time is 'End time of availability';
