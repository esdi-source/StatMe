-- ==========================================================================
-- COMPLETE DATABASE RESTORE SCRIPT
-- Führe dieses gesamte Skript im Supabase Dashboard SQL Editor aus
-- ==========================================================================

-- Extensions aktivieren
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Update-At Trigger Function
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- ============================================================================
-- PROFILES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    display_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- TODOS TABLES
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.todos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    is_recurring BOOLEAN NOT NULL DEFAULT FALSE,
    rrule TEXT,
    due_date DATE,
    priority INTEGER NOT NULL DEFAULT 0 CHECK (priority >= 0 AND priority <= 2),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_todos_user_id ON public.todos(user_id);
CREATE INDEX IF NOT EXISTS idx_todos_due_date ON public.todos(due_date);

CREATE TABLE IF NOT EXISTS public.todo_occurrences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    todo_id UUID NOT NULL REFERENCES public.todos(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    occurrence_date DATE NOT NULL,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(todo_id, occurrence_date)
);

CREATE INDEX IF NOT EXISTS idx_todo_occurrences_user_id ON public.todo_occurrences(user_id);
CREATE INDEX IF NOT EXISTS idx_todo_occurrences_todo_id ON public.todo_occurrences(todo_id);
CREATE INDEX IF NOT EXISTS idx_todo_occurrences_date ON public.todo_occurrences(occurrence_date);

-- ============================================================================
-- PRODUCTS CACHE TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.products_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    barcode TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    brand TEXT,
    calories_per_100g DOUBLE PRECISION NOT NULL DEFAULT 0,
    protein_per_100g DOUBLE PRECISION NOT NULL DEFAULT 0,
    carbs_per_100g DOUBLE PRECISION NOT NULL DEFAULT 0,
    fat_per_100g DOUBLE PRECISION NOT NULL DEFAULT 0,
    fiber_per_100g DOUBLE PRECISION NOT NULL DEFAULT 0,
    sugar_per_100g DOUBLE PRECISION NOT NULL DEFAULT 0,
    sodium_per_100g DOUBLE PRECISION NOT NULL DEFAULT 0,
    serving_size_g DOUBLE PRECISION NOT NULL DEFAULT 100,
    image_url TEXT,
    source TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_products_cache_barcode ON public.products_cache(barcode);

-- ============================================================================
-- FOOD LOGS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.food_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products_cache(id),
    custom_name TEXT,
    date DATE NOT NULL,
    meal_type TEXT NOT NULL DEFAULT 'snack' CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
    serving_size_g DOUBLE PRECISION NOT NULL,
    calories DOUBLE PRECISION NOT NULL,
    protein DOUBLE PRECISION NOT NULL DEFAULT 0,
    carbs DOUBLE PRECISION NOT NULL DEFAULT 0,
    fat DOUBLE PRECISION NOT NULL DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_food_logs_user_id ON public.food_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_food_logs_date ON public.food_logs(date);
CREATE INDEX IF NOT EXISTS idx_food_logs_user_date ON public.food_logs(user_id, date);

-- ============================================================================
-- WATER LOGS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.water_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    amount_ml INTEGER NOT NULL CHECK (amount_ml > 0),
    logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_water_logs_user_id ON public.water_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_water_logs_date ON public.water_logs(date);
CREATE INDEX IF NOT EXISTS idx_water_logs_user_date ON public.water_logs(user_id, date);

-- ============================================================================
-- STEPS LOGS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.steps_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    steps INTEGER NOT NULL CHECK (steps >= 0),
    distance_km DOUBLE PRECISION,
    source TEXT NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'apple_health', 'google_fit', 'fitbit')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, date, source)
);

CREATE INDEX IF NOT EXISTS idx_steps_logs_user_id ON public.steps_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_steps_logs_date ON public.steps_logs(date);
CREATE INDEX IF NOT EXISTS idx_steps_logs_user_date ON public.steps_logs(user_id, date);

-- ============================================================================
-- SLEEP LOGS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.sleep_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    bedtime TIMESTAMPTZ NOT NULL,
    wake_time TIMESTAMPTZ NOT NULL,
    quality INTEGER CHECK (quality >= 1 AND quality <= 5),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sleep_logs_user_id ON public.sleep_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_sleep_logs_date ON public.sleep_logs(date);
CREATE INDEX IF NOT EXISTS idx_sleep_logs_user_date ON public.sleep_logs(user_id, date);

-- ============================================================================
-- MOOD LOGS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.mood_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    mood_score INTEGER NOT NULL CHECK (mood_score >= 1 AND mood_score <= 10),
    energy_level INTEGER CHECK (energy_level >= 1 AND energy_level <= 10),
    stress_level INTEGER CHECK (stress_level >= 1 AND stress_level <= 10),
    notes TEXT,
    tags TEXT[],
    logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mood_logs_user_id ON public.mood_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_mood_logs_date ON public.mood_logs(date);
CREATE INDEX IF NOT EXISTS idx_mood_logs_user_date ON public.mood_logs(user_id, date);

-- ============================================================================
-- SETTINGS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    theme_mode TEXT NOT NULL DEFAULT 'system' CHECK (theme_mode IN ('light', 'dark', 'system')),
    locale TEXT NOT NULL DEFAULT 'en',
    daily_calorie_goal INTEGER NOT NULL DEFAULT 2000,
    daily_water_goal_ml INTEGER NOT NULL DEFAULT 2000,
    daily_steps_goal INTEGER NOT NULL DEFAULT 10000,
    sleep_goal_hours DOUBLE PRECISION NOT NULL DEFAULT 8.0,
    notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    water_reminder_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    water_reminder_interval_minutes INTEGER NOT NULL DEFAULT 60,
    share_stats_publicly BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_settings_user_id ON public.settings(user_id);

-- ============================================================================
-- BOOKS TABLES
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.books (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    author TEXT,
    cover_url TEXT,
    google_books_id TEXT,
    isbn TEXT,
    isbn10 TEXT,
    isbn13 TEXT,
    page_count INTEGER,
    status TEXT NOT NULL DEFAULT 'want_to_read' CHECK (status IN ('want_to_read', 'reading', 'finished', 'abandoned')),
    current_page INTEGER DEFAULT 0,
    rating_overall INTEGER CHECK (rating_overall >= 1 AND rating_overall <= 5),
    rating_story INTEGER CHECK (rating_story >= 1 AND rating_story <= 5),
    rating_characters INTEGER CHECK (rating_characters >= 1 AND rating_characters <= 5),
    rating_writing INTEGER CHECK (rating_writing >= 1 AND rating_writing <= 5),
    rating_pacing INTEGER CHECK (rating_pacing >= 1 AND rating_pacing <= 5),
    rating_emotional_impact INTEGER CHECK (rating_emotional_impact >= 1 AND rating_emotional_impact <= 5),
    rating_note TEXT,
    added_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    notes TEXT,
    cover_status TEXT DEFAULT 'pending' CHECK (cover_status IN ('pending', 'ok', 'missing', 'error', 'user_upload')),
    last_cover_attempt_at TIMESTAMPTZ,
    cover_attempts INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_books_user_id ON public.books(user_id);
CREATE INDEX IF NOT EXISTS idx_books_isbn ON public.books(isbn);
CREATE INDEX IF NOT EXISTS idx_books_isbn13 ON public.books(isbn13);
CREATE INDEX IF NOT EXISTS idx_books_cover_status ON public.books(cover_status);
CREATE INDEX IF NOT EXISTS idx_books_google_books_id ON public.books(google_books_id);

CREATE TABLE IF NOT EXISTS public.reading_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    weekly_goal_minutes INTEGER NOT NULL DEFAULT 120,
    week_start_date DATE NOT NULL,
    read_minutes_this_week INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, week_start_date)
);

CREATE INDEX IF NOT EXISTS idx_reading_goals_user ON public.reading_goals(user_id);

CREATE TABLE IF NOT EXISTS public.reading_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    book_id UUID REFERENCES public.books(id) ON DELETE SET NULL,
    duration_minutes INTEGER NOT NULL,
    pages_read INTEGER,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reading_sessions_user ON public.reading_sessions(user_id);

CREATE TABLE IF NOT EXISTS public.book_covers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    book_id UUID NOT NULL REFERENCES public.books(id) ON DELETE CASCADE,
    source TEXT NOT NULL,
    source_id TEXT,
    source_url TEXT,
    storage_path TEXT,
    cdn_url TEXT,
    width INTEGER,
    height INTEGER,
    file_size INTEGER,
    mime_type TEXT,
    status TEXT DEFAULT 'pending',
    error_message TEXT,
    match_confidence DOUBLE PRECISION,
    match_method TEXT,
    attempts INTEGER DEFAULT 0,
    fetched_at TIMESTAMPTZ,
    raw_response JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(book_id, source)
);

CREATE INDEX IF NOT EXISTS idx_book_covers_book_id ON public.book_covers(book_id);
CREATE INDEX IF NOT EXISTS idx_book_covers_status ON public.book_covers(status);

-- ============================================================================
-- SCHOOL TABLES
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.subjects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    short_name TEXT,
    color_value INTEGER,
    fun_factor INTEGER CHECK (fun_factor >= 1 AND fun_factor <= 5),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subjects_user ON public.subjects(user_id);

CREATE TABLE IF NOT EXISTS public.timetable_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES public.subjects(id) ON DELETE CASCADE,
    weekday INTEGER NOT NULL CHECK (weekday >= 1 AND weekday <= 7),
    lesson_number INTEGER NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    room TEXT,
    teacher TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_timetable_user ON public.timetable_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_timetable_weekday ON public.timetable_entries(user_id, weekday);

CREATE TABLE IF NOT EXISTS public.grades (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES public.subjects(id) ON DELETE CASCADE,
    points INTEGER NOT NULL CHECK (points >= 0 AND points <= 15),
    grade_type TEXT NOT NULL DEFAULT 'test',
    weight DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    date DATE NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_grades_user ON public.grades(user_id);
CREATE INDEX IF NOT EXISTS idx_grades_subject ON public.grades(subject_id);

CREATE TABLE IF NOT EXISTS public.study_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES public.subjects(id) ON DELETE SET NULL,
    start_time TIMESTAMPTZ NOT NULL,
    duration_minutes INTEGER NOT NULL,
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_study_sessions_user ON public.study_sessions(user_id);

CREATE TABLE IF NOT EXISTS public.homework (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES public.subjects(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT,
    due_date DATE NOT NULL,
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'done')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_homework_user ON public.homework(user_id);
CREATE INDEX IF NOT EXISTS idx_homework_due ON public.homework(user_id, due_date);

CREATE TABLE IF NOT EXISTS public.school_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES public.subjects(id) ON DELETE SET NULL,
    event_type TEXT NOT NULL,
    title TEXT NOT NULL,
    date DATE NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_school_events_user ON public.school_events(user_id);

CREATE TABLE IF NOT EXISTS public.school_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES public.subjects(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    content TEXT,
    is_pinned BOOLEAN NOT NULL DEFAULT FALSE,
    color_value INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_school_notes_user ON public.school_notes(user_id);

-- ============================================================================
-- SPORT TABLES
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.sport_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    icon TEXT,
    calories_per_hour INTEGER NOT NULL DEFAULT 300,
    color_value INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sport_types_user ON public.sport_types(user_id);

CREATE TABLE IF NOT EXISTS public.sport_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    sport_type_id UUID REFERENCES public.sport_types(id) ON DELETE SET NULL,
    date DATE NOT NULL,
    start_time TIMESTAMPTZ,
    duration_minutes INTEGER NOT NULL,
    distance_km DOUBLE PRECISION,
    calories_burned DOUBLE PRECISION,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sport_sessions_user ON public.sport_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sport_sessions_date ON public.sport_sessions(user_id, date);

CREATE TABLE IF NOT EXISTS public.sport_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    sport_type_id UUID REFERENCES public.sport_types(id) ON DELETE SET NULL,
    frequency TEXT NOT NULL DEFAULT 'weekly',
    target_minutes INTEGER,
    target_sessions INTEGER,
    target_distance_km DOUBLE PRECISION,
    active_from DATE NOT NULL DEFAULT CURRENT_DATE,
    active_until DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sport_goals_user ON public.sport_goals(user_id);

-- ============================================================================
-- HABITS TABLES
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.habits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    icon TEXT,
    color_value INTEGER,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    frequency TEXT NOT NULL DEFAULT 'daily',
    target_per_period INTEGER NOT NULL DEFAULT 1,
    reminder_time TIME,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_habits_user ON public.habits(user_id);

CREATE TABLE IF NOT EXISTS public.habit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    habit_id UUID NOT NULL REFERENCES public.habits(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    count INTEGER NOT NULL DEFAULT 1,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(habit_id, date)
);

CREATE INDEX IF NOT EXISTS idx_habit_logs_user ON public.habit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_habit_logs_habit ON public.habit_logs(habit_id);
CREATE INDEX IF NOT EXISTS idx_habit_logs_date ON public.habit_logs(user_id, date);

-- ============================================================================
-- CALENDAR EVENTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.calendar_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    is_all_day BOOLEAN NOT NULL DEFAULT FALSE,
    location TEXT,
    color_value INTEGER,
    reminder_minutes INTEGER,
    recurrence_rule TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_calendar_events_user ON public.calendar_events(user_id);
CREATE INDEX IF NOT EXISTS idx_calendar_events_time ON public.calendar_events(user_id, start_time);

-- ============================================================================
-- MICRO WIDGETS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.micro_widgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    icon TEXT,
    color_value INTEGER,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    type TEXT DEFAULT 'custom',
    target_count INTEGER DEFAULT 1,
    frequency TEXT DEFAULT 'weekly',
    period_start TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_micro_widgets_user ON public.micro_widgets(user_id);
CREATE INDEX IF NOT EXISTS idx_micro_widgets_type ON public.micro_widgets(type);

CREATE TABLE IF NOT EXISTS public.micro_widget_completions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    widget_id UUID NOT NULL REFERENCES public.micro_widgets(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    count INTEGER NOT NULL DEFAULT 1,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_micro_widget_completions_user ON public.micro_widget_completions(user_id);
CREATE INDEX IF NOT EXISTS idx_micro_widget_completions_widget ON public.micro_widget_completions(widget_id);

-- ============================================================================
-- TIMER SESSIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.timer_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    label TEXT,
    duration_seconds INTEGER NOT NULL,
    type TEXT NOT NULL DEFAULT 'focus',
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_timer_sessions_user ON public.timer_sessions(user_id);

-- ============================================================================
-- EVENT LOG TABLE
-- ============================================================================
DO $$ BEGIN
    CREATE TYPE event_type AS ENUM (
      'create', 'update', 'delete', 'complete', 'skip', 
      'log', 'start', 'end', 'import', 'migration'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS public.event_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    widget_name TEXT NOT NULL,
    event_type event_type NOT NULL DEFAULT 'log',
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reference_id TEXT,
    payload JSONB NOT NULL DEFAULT '{}',
    client_timestamp TIMESTAMPTZ,
    client_version TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_event_log_user_time ON public.event_log (user_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_event_log_user_widget ON public.event_log (user_id, widget_name, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_event_log_stats ON public.event_log (user_id, widget_name, event_type, timestamp);
CREATE INDEX IF NOT EXISTS idx_event_log_payload ON public.event_log USING GIN (payload);

-- ============================================================================
-- FAVORITE PRODUCTS TABLE (für Food Favorites)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.favorite_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    kcal_per_100g DOUBLE PRECISION NOT NULL,
    protein_per_100g DOUBLE PRECISION,
    carbs_per_100g DOUBLE PRECISION,
    fat_per_100g DOUBLE PRECISION,
    barcode TEXT,
    image_url TEXT,
    default_grams DOUBLE PRECISION DEFAULT 100,
    use_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_favorite_products_user_id ON public.favorite_products(user_id);
CREATE INDEX IF NOT EXISTS idx_favorite_products_barcode ON public.favorite_products(barcode);

-- ============================================================================
-- CUSTOM FOOD PRODUCTS TABLE (für eigene Rezepte)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.custom_food_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    kcal_per_100g DOUBLE PRECISION NOT NULL,
    protein_per_100g DOUBLE PRECISION,
    carbs_per_100g DOUBLE PRECISION,
    fat_per_100g DOUBLE PRECISION,
    default_serving_grams DOUBLE PRECISION,
    ingredients JSONB DEFAULT '[]'::jsonb,
    image_url TEXT,
    is_recipe BOOLEAN DEFAULT false,
    use_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_custom_food_products_user_id ON public.custom_food_products(user_id);
CREATE INDEX IF NOT EXISTS idx_custom_food_products_is_recipe ON public.custom_food_products(is_recipe);

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.todos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.todo_occurrences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.food_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.water_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.steps_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sleep_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mood_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.books ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reading_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reading_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.book_covers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.timetable_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.grades ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.study_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.homework ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.school_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.school_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sport_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sport_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sport_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.habit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.micro_widgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.micro_widget_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.timer_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorite_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.custom_food_products ENABLE ROW LEVEL SECURITY;

-- Profiles policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Products cache - public read
DROP POLICY IF EXISTS "Anyone can view products" ON public.products_cache;
CREATE POLICY "Anyone can view products" ON public.products_cache FOR SELECT USING (true);

-- Generic user_id based policies for all other tables
DO $$ 
DECLARE
    tbl_name TEXT;
    tbl_names TEXT[] := ARRAY[
        'todos', 'todo_occurrences', 'food_logs', 'water_logs', 'steps_logs', 
        'sleep_logs', 'mood_logs', 'settings', 'books', 'reading_goals', 
        'reading_sessions', 'subjects', 'timetable_entries', 'grades', 
        'study_sessions', 'homework', 'school_events', 'school_notes', 
        'sport_types', 'sport_sessions', 'sport_goals', 'habits', 'habit_logs',
        'calendar_events', 'micro_widgets', 'micro_widget_completions', 
        'timer_sessions', 'event_log', 'favorite_products', 'custom_food_products'
    ];
BEGIN
    FOREACH tbl_name IN ARRAY tbl_names
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS "Users can view own %s" ON public.%I', tbl_name, tbl_name);
        EXECUTE format('CREATE POLICY "Users can view own %s" ON public.%I FOR SELECT USING (auth.uid() = user_id)', tbl_name, tbl_name);
        
        EXECUTE format('DROP POLICY IF EXISTS "Users can create own %s" ON public.%I', tbl_name, tbl_name);
        EXECUTE format('CREATE POLICY "Users can create own %s" ON public.%I FOR INSERT WITH CHECK (auth.uid() = user_id)', tbl_name, tbl_name);
        
        EXECUTE format('DROP POLICY IF EXISTS "Users can update own %s" ON public.%I', tbl_name, tbl_name);
        EXECUTE format('CREATE POLICY "Users can update own %s" ON public.%I FOR UPDATE USING (auth.uid() = user_id)', tbl_name, tbl_name);
        
        EXECUTE format('DROP POLICY IF EXISTS "Users can delete own %s" ON public.%I', tbl_name, tbl_name);
        EXECUTE format('CREATE POLICY "Users can delete own %s" ON public.%I FOR DELETE USING (auth.uid() = user_id)', tbl_name, tbl_name);
    END LOOP;
END $$;

-- Book covers - access via books
DROP POLICY IF EXISTS "Users can view own book covers" ON public.book_covers;
CREATE POLICY "Users can view own book covers" ON public.book_covers FOR SELECT 
    USING (book_id IN (SELECT id FROM public.books WHERE user_id = auth.uid()));

-- ============================================================================
-- USER CREATION TRIGGER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, display_name)
    VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)));
    
    INSERT INTO public.settings (user_id)
    VALUES (NEW.id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- UPDATED_AT TRIGGERS
-- ============================================================================
DO $$ 
DECLARE
    tbl_name TEXT;
    tbl_names TEXT[] := ARRAY[
        'profiles', 'todos', 'todo_occurrences', 'products_cache', 'food_logs',
        'steps_logs', 'sleep_logs', 'settings', 'books', 'reading_goals',
        'book_covers', 'subjects', 'timetable_entries', 'grades', 'homework',
        'school_events', 'school_notes', 'sport_types', 'sport_sessions', 
        'sport_goals', 'habits', 'calendar_events', 'micro_widgets',
        'favorite_products', 'custom_food_products'
    ];
BEGIN
    FOREACH tbl_name IN ARRAY tbl_names
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS update_%s_updated_at ON public.%I', tbl_name, tbl_name);
        EXECUTE format('CREATE TRIGGER update_%s_updated_at BEFORE UPDATE ON public.%I FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()', tbl_name, tbl_name);
    END LOOP;
END $$;

-- Done!
SELECT 'Database restoration complete!' as status;
