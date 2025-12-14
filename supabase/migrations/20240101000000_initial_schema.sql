-- StatMe Initial Schema Migration
-- This creates all tables needed for the health/productivity tracking app

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- PROFILES TABLE (extends auth.users)
-- ============================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    display_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- TODOS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.todos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    is_recurring BOOLEAN NOT NULL DEFAULT FALSE,
    rrule TEXT, -- RFC5545 RRULE string for recurrence
    due_date DATE,
    priority INTEGER NOT NULL DEFAULT 0 CHECK (priority >= 0 AND priority <= 2), -- 0=low, 1=medium, 2=high
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_todos_user_id ON public.todos(user_id);
CREATE INDEX idx_todos_due_date ON public.todos(due_date);

-- ============================================
-- TODO OCCURRENCES TABLE (for recurring todos)
-- ============================================
CREATE TABLE IF NOT EXISTS public.todo_occurrences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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

CREATE INDEX idx_todo_occurrences_user_id ON public.todo_occurrences(user_id);
CREATE INDEX idx_todo_occurrences_todo_id ON public.todo_occurrences(todo_id);
CREATE INDEX idx_todo_occurrences_date ON public.todo_occurrences(occurrence_date);

-- ============================================
-- PRODUCTS CACHE TABLE (for barcode lookups)
-- ============================================
CREATE TABLE IF NOT EXISTS public.products_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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
    source TEXT, -- 'openfoodfacts', 'usda', 'manual'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_products_cache_barcode ON public.products_cache(barcode);

-- ============================================
-- FOOD LOGS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.food_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products_cache(id),
    custom_name TEXT, -- for manual entries without barcode
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

CREATE INDEX idx_food_logs_user_id ON public.food_logs(user_id);
CREATE INDEX idx_food_logs_date ON public.food_logs(date);
CREATE INDEX idx_food_logs_user_date ON public.food_logs(user_id, date);

-- ============================================
-- WATER LOGS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.water_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    amount_ml INTEGER NOT NULL CHECK (amount_ml > 0),
    logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_water_logs_user_id ON public.water_logs(user_id);
CREATE INDEX idx_water_logs_date ON public.water_logs(date);
CREATE INDEX idx_water_logs_user_date ON public.water_logs(user_id, date);

-- ============================================
-- STEPS LOGS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.steps_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    steps INTEGER NOT NULL CHECK (steps >= 0),
    distance_km DOUBLE PRECISION, -- optional, can be calculated
    source TEXT NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'apple_health', 'google_fit', 'fitbit')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, date, source) -- one entry per user per day per source
);

CREATE INDEX idx_steps_logs_user_id ON public.steps_logs(user_id);
CREATE INDEX idx_steps_logs_date ON public.steps_logs(date);
CREATE INDEX idx_steps_logs_user_date ON public.steps_logs(user_id, date);

-- ============================================
-- SLEEP LOGS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.sleep_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL, -- the date the sleep is attributed to (usually wake date)
    bedtime TIMESTAMPTZ NOT NULL,
    wake_time TIMESTAMPTZ NOT NULL,
    quality INTEGER CHECK (quality >= 1 AND quality <= 5), -- 1-5 rating
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sleep_logs_user_id ON public.sleep_logs(user_id);
CREATE INDEX idx_sleep_logs_date ON public.sleep_logs(date);
CREATE INDEX idx_sleep_logs_user_date ON public.sleep_logs(user_id, date);

-- ============================================
-- MOOD LOGS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.mood_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    mood_score INTEGER NOT NULL CHECK (mood_score >= 1 AND mood_score <= 10), -- 1-10 scale
    energy_level INTEGER CHECK (energy_level >= 1 AND energy_level <= 10),
    stress_level INTEGER CHECK (stress_level >= 1 AND stress_level <= 10),
    notes TEXT,
    tags TEXT[], -- array of mood tags like ['happy', 'productive', 'anxious']
    logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_mood_logs_user_id ON public.mood_logs(user_id);
CREATE INDEX idx_mood_logs_date ON public.mood_logs(date);
CREATE INDEX idx_mood_logs_user_date ON public.mood_logs(user_id, date);

-- ============================================
-- SETTINGS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Display preferences
    theme_mode TEXT NOT NULL DEFAULT 'system' CHECK (theme_mode IN ('light', 'dark', 'system')),
    locale TEXT NOT NULL DEFAULT 'en',
    
    -- Goals
    daily_calorie_goal INTEGER NOT NULL DEFAULT 2000,
    daily_water_goal_ml INTEGER NOT NULL DEFAULT 2000,
    daily_steps_goal INTEGER NOT NULL DEFAULT 10000,
    sleep_goal_hours DOUBLE PRECISION NOT NULL DEFAULT 8.0,
    
    -- Notification preferences
    notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    water_reminder_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    water_reminder_interval_minutes INTEGER NOT NULL DEFAULT 60,
    
    -- Privacy
    share_stats_publicly BOOLEAN NOT NULL DEFAULT FALSE,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_settings_user_id ON public.settings(user_id);

-- ============================================
-- UPDATED_AT TRIGGER FUNCTION
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers to all tables
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_todos_updated_at BEFORE UPDATE ON public.todos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_todo_occurrences_updated_at BEFORE UPDATE ON public.todo_occurrences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_cache_updated_at BEFORE UPDATE ON public.products_cache
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_food_logs_updated_at BEFORE UPDATE ON public.food_logs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_steps_logs_updated_at BEFORE UPDATE ON public.steps_logs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sleep_logs_updated_at BEFORE UPDATE ON public.sleep_logs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_settings_updated_at BEFORE UPDATE ON public.settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- FUNCTION: Create profile on user signup
-- ============================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, display_name)
    VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)));
    
    -- Also create default settings for the user
    INSERT INTO public.settings (user_id)
    VALUES (NEW.id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on signup
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
