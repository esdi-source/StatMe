-- ============================================================================
-- COMPLETE WIDGET TABLES - Alle Widgets auf Supabase
-- ============================================================================
-- Diese Migration fügt alle fehlenden Tabellen hinzu, damit ALLE Widget-Daten
-- benutzerspezifisch in Supabase gespeichert werden.
-- ============================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create update_updated_at_column function if it doesn't exist
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- ============================================
-- BOOKS TABLES
-- ============================================

CREATE TABLE IF NOT EXISTS public.books (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    author TEXT,
    cover_url TEXT,
    google_books_id TEXT,
    isbn TEXT,
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
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_books_user_id ON public.books(user_id);
CREATE INDEX idx_books_status ON public.books(user_id, status);

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

CREATE INDEX idx_reading_goals_user ON public.reading_goals(user_id);

CREATE TABLE IF NOT EXISTS public.reading_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    book_id UUID REFERENCES public.books(id) ON DELETE SET NULL,
    duration_minutes INTEGER NOT NULL,
    pages_read INTEGER,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reading_sessions_user ON public.reading_sessions(user_id);

-- ============================================
-- SCHOOL TABLES
-- ============================================

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

CREATE INDEX idx_subjects_user ON public.subjects(user_id);

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

CREATE INDEX idx_timetable_user ON public.timetable_entries(user_id);
CREATE INDEX idx_timetable_weekday ON public.timetable_entries(user_id, weekday);

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

CREATE INDEX idx_grades_user ON public.grades(user_id);
CREATE INDEX idx_grades_subject ON public.grades(subject_id);

CREATE TABLE IF NOT EXISTS public.study_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES public.subjects(id) ON DELETE SET NULL,
    start_time TIMESTAMPTZ NOT NULL,
    duration_minutes INTEGER NOT NULL,
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_study_sessions_user ON public.study_sessions(user_id);

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

CREATE INDEX idx_homework_user ON public.homework(user_id);
CREATE INDEX idx_homework_due ON public.homework(user_id, due_date);

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

CREATE INDEX idx_school_events_user ON public.school_events(user_id);

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

CREATE INDEX idx_school_notes_user ON public.school_notes(user_id);

-- ============================================
-- SPORT TABLES
-- ============================================

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

CREATE INDEX idx_sport_types_user ON public.sport_types(user_id);

CREATE TABLE IF NOT EXISTS public.sport_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    sport_type TEXT NOT NULL,
    duration_minutes INTEGER NOT NULL,
    intensity TEXT NOT NULL DEFAULT 'medium' CHECK (intensity IN ('low', 'medium', 'high', 'extreme')),
    calories_burned INTEGER,
    notes TEXT,
    date TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sport_sessions_user ON public.sport_sessions(user_id);
CREATE INDEX idx_sport_sessions_date ON public.sport_sessions(user_id, date);

CREATE TABLE IF NOT EXISTS public.weight_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    weight_kg DOUBLE PRECISION NOT NULL,
    date DATE NOT NULL,
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, date)
);

CREATE INDEX idx_weight_entries_user ON public.weight_entries(user_id);

CREATE TABLE IF NOT EXISTS public.workout_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    plan_type TEXT NOT NULL DEFAULT 'custom',
    exercises JSONB NOT NULL DEFAULT '[]',
    rest_between_exercises_seconds INTEGER DEFAULT 60,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_workout_plans_user ON public.workout_plans(user_id);

-- ============================================
-- SKIN CARE TABLES
-- ============================================

CREATE TABLE IF NOT EXISTS public.skin_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    overall_condition INTEGER CHECK (overall_condition >= 1 AND overall_condition <= 5),
    area_conditions JSONB DEFAULT '{}',
    attributes JSONB DEFAULT '{}',
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, date)
);

CREATE INDEX idx_skin_entries_user ON public.skin_entries(user_id);

CREATE TABLE IF NOT EXISTS public.skin_care_steps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    step_order INTEGER NOT NULL DEFAULT 0,
    is_daily BOOLEAN NOT NULL DEFAULT TRUE,
    weekdays INTEGER[] DEFAULT ARRAY[1,2,3,4,5,6,7],
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_skin_care_steps_user ON public.skin_care_steps(user_id);

CREATE TABLE IF NOT EXISTS public.skin_care_completions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    step_id UUID REFERENCES public.skin_care_steps(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(step_id, date)
);

CREATE INDEX idx_skin_care_completions_user ON public.skin_care_completions(user_id);

CREATE TABLE IF NOT EXISTS public.skin_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    brand TEXT,
    category TEXT,
    tolerance TEXT DEFAULT 'unknown',
    notes TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_skin_products_user ON public.skin_products(user_id);

CREATE TABLE IF NOT EXISTS public.skin_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_skin_notes_user ON public.skin_notes(user_id);

CREATE TABLE IF NOT EXISTS public.skin_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    file_path TEXT NOT NULL,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_skin_photos_user ON public.skin_photos(user_id);

-- ============================================
-- HAIR CARE TABLES
-- ============================================

CREATE TABLE IF NOT EXISTS public.hair_care_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    care_types TEXT[] NOT NULL DEFAULT '{}',
    custom_products TEXT[] DEFAULT '{}',
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, date)
);

CREATE INDEX idx_hair_care_entries_user ON public.hair_care_entries(user_id);

CREATE TABLE IF NOT EXISTS public.hair_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    event_type TEXT NOT NULL,
    title TEXT,
    note TEXT,
    salon_name TEXT,
    cost DOUBLE PRECISION,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_hair_events_user ON public.hair_events(user_id);

CREATE TABLE IF NOT EXISTS public.hair_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    brand TEXT,
    category TEXT,
    reaction TEXT DEFAULT 'neutral',
    notes TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_hair_products_user ON public.hair_products(user_id);

-- ============================================
-- SUPPLEMENTS TABLES
-- ============================================

CREATE TABLE IF NOT EXISTS public.supplements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    brand TEXT,
    category TEXT,
    form TEXT,
    ingredients JSONB DEFAULT '[]',
    default_dosage DOUBLE PRECISION,
    dosage_unit TEXT DEFAULT 'mg',
    recommended_times TEXT[] DEFAULT '{}',
    is_paused BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_supplements_user ON public.supplements(user_id);

CREATE TABLE IF NOT EXISTS public.supplement_intakes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    supplement_id UUID REFERENCES public.supplements(id) ON DELETE CASCADE,
    dosage DOUBLE PRECISION NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_supplement_intakes_user ON public.supplement_intakes(user_id);
CREATE INDEX idx_supplement_intakes_supplement ON public.supplement_intakes(supplement_id);

-- ============================================
-- DIGESTION TABLES
-- ============================================

CREATE TABLE IF NOT EXISTS public.digestion_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    entry_type TEXT NOT NULL,
    consistency INTEGER CHECK (consistency >= 1 AND consistency <= 7),
    amount TEXT,
    feeling TEXT,
    has_pain BOOLEAN DEFAULT FALSE,
    has_bloating BOOLEAN DEFAULT FALSE,
    has_urgency BOOLEAN DEFAULT FALSE,
    note TEXT,
    linked_food_ids TEXT[] DEFAULT '{}',
    water_intake_last_24h INTEGER,
    stress_level INTEGER CHECK (stress_level >= 1 AND stress_level <= 10),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_digestion_entries_user ON public.digestion_entries(user_id);
CREATE INDEX idx_digestion_entries_timestamp ON public.digestion_entries(user_id, timestamp);

-- ============================================
-- MEDIA (MOVIES/SERIES) TABLES
-- ============================================

CREATE TABLE IF NOT EXISTS public.user_media (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    tmdb_id INTEGER NOT NULL,
    media_type TEXT NOT NULL CHECK (media_type IN ('movie', 'tv')),
    title TEXT NOT NULL,
    poster_path TEXT,
    backdrop_path TEXT,
    overview TEXT,
    release_date TEXT,
    genres JSONB DEFAULT '[]',
    runtime INTEGER,
    vote_average DOUBLE PRECISION,
    status TEXT NOT NULL DEFAULT 'watchlist' CHECK (status IN ('watchlist', 'watching', 'finished', 'abandoned')),
    rating_overall INTEGER CHECK (rating_overall >= 1 AND rating_overall <= 10),
    rating_story INTEGER CHECK (rating_story >= 1 AND rating_story <= 10),
    rating_acting INTEGER CHECK (rating_acting >= 1 AND rating_acting <= 10),
    rating_visuals INTEGER CHECK (rating_visuals >= 1 AND rating_visuals <= 10),
    rating_notes TEXT,
    watched_date DATE,
    watched_episodes INTEGER DEFAULT 0,
    current_season INTEGER DEFAULT 1,
    current_episode INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, tmdb_id, media_type)
);

CREATE INDEX idx_user_media_user ON public.user_media(user_id);
CREATE INDEX idx_user_media_status ON public.user_media(user_id, status);

-- ============================================
-- HOUSEHOLD TABLES
-- ============================================

CREATE TABLE IF NOT EXISTS public.household_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    category TEXT,
    frequency TEXT NOT NULL DEFAULT 'weekly',
    frequency_days INTEGER DEFAULT 7,
    estimated_minutes INTEGER DEFAULT 15,
    energy_level TEXT DEFAULT 'medium',
    room TEXT,
    notes TEXT,
    is_paused BOOLEAN NOT NULL DEFAULT FALSE,
    last_completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_household_tasks_user ON public.household_tasks(user_id);

CREATE TABLE IF NOT EXISTS public.household_completions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    task_id UUID REFERENCES public.household_tasks(id) ON DELETE CASCADE,
    completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    was_skipped BOOLEAN NOT NULL DEFAULT FALSE,
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_household_completions_user ON public.household_completions(user_id);
CREATE INDEX idx_household_completions_task ON public.household_completions(task_id);

-- ============================================
-- RECIPES TABLES
-- ============================================

CREATE TABLE IF NOT EXISTS public.recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    image_url TEXT,
    source_url TEXT,
    ingredients JSONB NOT NULL DEFAULT '[]',
    steps JSONB NOT NULL DEFAULT '[]',
    servings INTEGER DEFAULT 4,
    prep_time_minutes INTEGER,
    cook_time_minutes INTEGER,
    category TEXT,
    tags TEXT[] DEFAULT '{}',
    calories_per_serving INTEGER,
    status TEXT NOT NULL DEFAULT 'saved' CHECK (status IN ('saved', 'want_to_try', 'tried', 'favorite')),
    is_favorite BOOLEAN NOT NULL DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_recipes_user ON public.recipes(user_id);
CREATE INDEX idx_recipes_status ON public.recipes(user_id, status);

CREATE TABLE IF NOT EXISTS public.recipe_cook_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    recipe_id UUID REFERENCES public.recipes(id) ON DELETE CASCADE,
    cooked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    servings_cooked INTEGER DEFAULT 1,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_recipe_cook_logs_user ON public.recipe_cook_logs(user_id);
CREATE INDEX idx_recipe_cook_logs_recipe ON public.recipe_cook_logs(recipe_id);

-- ============================================
-- TIMER/ACTIVITY TABLES
-- ============================================

CREATE TABLE IF NOT EXISTS public.timer_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    activity_name TEXT NOT NULL,
    duration_seconds INTEGER NOT NULL,
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    category TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_timer_sessions_user ON public.timer_sessions(user_id);
CREATE INDEX idx_timer_sessions_date ON public.timer_sessions(user_id, started_at);

-- ============================================
-- MICRO WIDGETS (HABITS) TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.micro_widgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    icon TEXT DEFAULT '✓',
    color_value INTEGER,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_micro_widgets_user ON public.micro_widgets(user_id);

CREATE TABLE IF NOT EXISTS public.micro_widget_completions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    widget_id UUID REFERENCES public.micro_widgets(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(widget_id, date)
);

CREATE INDEX idx_micro_widget_completions_user ON public.micro_widget_completions(user_id);

-- ============================================
-- HOME SCREEN CONFIG TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.home_screen_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    widgets JSONB NOT NULL DEFAULT '[]',
    grid_columns INTEGER NOT NULL DEFAULT 2,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_home_screen_config_user ON public.home_screen_config(user_id);

-- ============================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.books ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reading_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reading_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.timetable_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.grades ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.study_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.homework ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.school_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.school_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sport_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sport_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weight_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.skin_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.skin_care_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.skin_care_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.skin_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.skin_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.skin_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hair_care_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hair_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hair_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.supplements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.supplement_intakes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.digestion_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.household_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.household_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recipe_cook_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.timer_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.micro_widgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.micro_widget_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.home_screen_config ENABLE ROW LEVEL SECURITY;

-- Create policies for all tables (user can only access own data)
DO $$
DECLARE
    t TEXT;
    tables TEXT[] := ARRAY[
        'books', 'reading_goals', 'reading_sessions',
        'subjects', 'timetable_entries', 'grades', 'study_sessions', 'homework', 'school_events', 'school_notes',
        'sport_types', 'sport_sessions', 'weight_entries', 'workout_plans',
        'skin_entries', 'skin_care_steps', 'skin_care_completions', 'skin_products', 'skin_notes', 'skin_photos',
        'hair_care_entries', 'hair_events', 'hair_products',
        'supplements', 'supplement_intakes',
        'digestion_entries',
        'user_media',
        'household_tasks', 'household_completions',
        'recipes', 'recipe_cook_logs',
        'timer_sessions',
        'micro_widgets', 'micro_widget_completions',
        'home_screen_config'
    ];
BEGIN
    FOREACH t IN ARRAY tables
    LOOP
        EXECUTE format('
            CREATE POLICY "Users can view own %1$s" ON public.%1$s
                FOR SELECT USING (auth.uid() = user_id);
            CREATE POLICY "Users can insert own %1$s" ON public.%1$s
                FOR INSERT WITH CHECK (auth.uid() = user_id);
            CREATE POLICY "Users can update own %1$s" ON public.%1$s
                FOR UPDATE USING (auth.uid() = user_id);
            CREATE POLICY "Users can delete own %1$s" ON public.%1$s
                FOR DELETE USING (auth.uid() = user_id);
        ', t);
    END LOOP;
END $$;

-- ============================================
-- UPDATED_AT TRIGGERS for new tables
-- ============================================

CREATE TRIGGER update_books_updated_at BEFORE UPDATE ON public.books
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_reading_goals_updated_at BEFORE UPDATE ON public.reading_goals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_subjects_updated_at BEFORE UPDATE ON public.subjects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_timetable_entries_updated_at BEFORE UPDATE ON public.timetable_entries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_grades_updated_at BEFORE UPDATE ON public.grades
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_homework_updated_at BEFORE UPDATE ON public.homework
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_school_events_updated_at BEFORE UPDATE ON public.school_events
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_school_notes_updated_at BEFORE UPDATE ON public.school_notes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_sport_types_updated_at BEFORE UPDATE ON public.sport_types
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_workout_plans_updated_at BEFORE UPDATE ON public.workout_plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_skin_entries_updated_at BEFORE UPDATE ON public.skin_entries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_skin_care_steps_updated_at BEFORE UPDATE ON public.skin_care_steps
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_skin_products_updated_at BEFORE UPDATE ON public.skin_products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_hair_products_updated_at BEFORE UPDATE ON public.hair_products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_supplements_updated_at BEFORE UPDATE ON public.supplements
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_media_updated_at BEFORE UPDATE ON public.user_media
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_household_tasks_updated_at BEFORE UPDATE ON public.household_tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_recipes_updated_at BEFORE UPDATE ON public.recipes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_micro_widgets_updated_at BEFORE UPDATE ON public.micro_widgets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_home_screen_config_updated_at BEFORE UPDATE ON public.home_screen_config
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
