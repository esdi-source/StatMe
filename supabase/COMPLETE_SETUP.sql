-- ============================================
-- STATME - KOMPLETTES DATENBANK-SETUP
-- ============================================
-- Kopiere ALLES und füge es im Supabase SQL Editor ein.
-- Klicke dann auf "Run" (grüner Button).
-- Das war's! ✅
-- ============================================

-- UUID Extension aktivieren
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- TABELLEN ERSTELLEN
-- ============================================

-- Benutzerprofile
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    display_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Einstellungen
CREATE TABLE IF NOT EXISTS public.settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    theme_mode TEXT NOT NULL DEFAULT 'system',
    theme_color_value INTEGER NOT NULL DEFAULT 4283215696,
    locale TEXT NOT NULL DEFAULT 'de',
    daily_calorie_goal INTEGER NOT NULL DEFAULT 2000,
    daily_water_goal_ml INTEGER NOT NULL DEFAULT 2500,
    daily_steps_goal INTEGER NOT NULL DEFAULT 10000,
    sleep_goal_hours DOUBLE PRECISION NOT NULL DEFAULT 8.0,
    notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Todos (Aufgaben)
CREATE TABLE IF NOT EXISTS public.todos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date DATE,
    rrule_text TEXT,
    timezone TEXT DEFAULT 'Europe/Berlin',
    active BOOLEAN NOT NULL DEFAULT TRUE,
    priority INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Todo-Vorkommen (für wiederkehrende Aufgaben)
CREATE TABLE IF NOT EXISTS public.todo_occurrences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    todo_id UUID NOT NULL REFERENCES public.todos(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    occurrence_date DATE NOT NULL,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(todo_id, occurrence_date)
);

-- Essen-Einträge
CREATE TABLE IF NOT EXISTS public.food_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    product_name TEXT NOT NULL,
    barcode TEXT,
    date DATE NOT NULL,
    grams DOUBLE PRECISION NOT NULL,
    calories DOUBLE PRECISION NOT NULL,
    protein DOUBLE PRECISION DEFAULT 0,
    carbs DOUBLE PRECISION DEFAULT 0,
    fat DOUBLE PRECISION DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Wasser-Einträge
CREATE TABLE IF NOT EXISTS public.water_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    amount_ml INTEGER NOT NULL,
    logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Schritte-Einträge
CREATE TABLE IF NOT EXISTS public.steps_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    steps INTEGER NOT NULL,
    source TEXT NOT NULL DEFAULT 'manual',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Schlaf-Einträge
CREATE TABLE IF NOT EXISTS public.sleep_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    sleep_start TIMESTAMPTZ NOT NULL,
    sleep_end TIMESTAMPTZ NOT NULL,
    quality INTEGER CHECK (quality >= 1 AND quality <= 10),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Stimmungs-Einträge
CREATE TABLE IF NOT EXISTS public.mood_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    mood_level INTEGER NOT NULL CHECK (mood_level >= 1 AND mood_level <= 10),
    energy_level INTEGER CHECK (energy_level >= 1 AND energy_level <= 10),
    notes TEXT,
    tags TEXT[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- INDIZES FÜR SCHNELLERE ABFRAGEN
-- ============================================
CREATE INDEX IF NOT EXISTS idx_todos_user ON public.todos(user_id);
CREATE INDEX IF NOT EXISTS idx_todo_occ_user_date ON public.todo_occurrences(user_id, occurrence_date);
CREATE INDEX IF NOT EXISTS idx_food_user_date ON public.food_logs(user_id, date);
CREATE INDEX IF NOT EXISTS idx_water_user_date ON public.water_logs(user_id, date);
CREATE INDEX IF NOT EXISTS idx_steps_user_date ON public.steps_logs(user_id, date);
CREATE INDEX IF NOT EXISTS idx_sleep_user_date ON public.sleep_logs(user_id, date);
CREATE INDEX IF NOT EXISTS idx_mood_user_date ON public.mood_logs(user_id, date);

-- ============================================
-- AUTOMATISCHE PROFIL-ERSTELLUNG BEI REGISTRIERUNG
-- ============================================
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

-- ============================================
-- ROW LEVEL SECURITY (RLS) AKTIVIEREN
-- ============================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.todos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.todo_occurrences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.food_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.water_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.steps_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sleep_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mood_logs ENABLE ROW LEVEL SECURITY;

-- ============================================
-- SICHERHEITS-POLICIES (Jeder sieht nur seine Daten)
-- ============================================

-- Profiles
CREATE POLICY "Eigenes Profil sehen" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Eigenes Profil bearbeiten" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Settings  
CREATE POLICY "Eigene Settings sehen" ON public.settings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Eigene Settings bearbeiten" ON public.settings FOR UPDATE USING (auth.uid() = user_id);

-- Todos
CREATE POLICY "Eigene Todos sehen" ON public.todos FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Eigene Todos erstellen" ON public.todos FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Eigene Todos bearbeiten" ON public.todos FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Eigene Todos löschen" ON public.todos FOR DELETE USING (auth.uid() = user_id);

-- Todo Occurrences
CREATE POLICY "Eigene Todo-Vorkommen sehen" ON public.todo_occurrences FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Eigene Todo-Vorkommen erstellen" ON public.todo_occurrences FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Eigene Todo-Vorkommen bearbeiten" ON public.todo_occurrences FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Eigene Todo-Vorkommen löschen" ON public.todo_occurrences FOR DELETE USING (auth.uid() = user_id);

-- Food Logs
CREATE POLICY "Eigene Food-Logs sehen" ON public.food_logs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Eigene Food-Logs erstellen" ON public.food_logs FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Eigene Food-Logs bearbeiten" ON public.food_logs FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Eigene Food-Logs löschen" ON public.food_logs FOR DELETE USING (auth.uid() = user_id);

-- Water Logs
CREATE POLICY "Eigene Water-Logs sehen" ON public.water_logs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Eigene Water-Logs erstellen" ON public.water_logs FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Eigene Water-Logs bearbeiten" ON public.water_logs FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Eigene Water-Logs löschen" ON public.water_logs FOR DELETE USING (auth.uid() = user_id);

-- Steps Logs
CREATE POLICY "Eigene Steps-Logs sehen" ON public.steps_logs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Eigene Steps-Logs erstellen" ON public.steps_logs FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Eigene Steps-Logs bearbeiten" ON public.steps_logs FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Eigene Steps-Logs löschen" ON public.steps_logs FOR DELETE USING (auth.uid() = user_id);

-- Sleep Logs
CREATE POLICY "Eigene Sleep-Logs sehen" ON public.sleep_logs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Eigene Sleep-Logs erstellen" ON public.sleep_logs FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Eigene Sleep-Logs bearbeiten" ON public.sleep_logs FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Eigene Sleep-Logs löschen" ON public.sleep_logs FOR DELETE USING (auth.uid() = user_id);

-- Mood Logs
CREATE POLICY "Eigene Mood-Logs sehen" ON public.mood_logs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Eigene Mood-Logs erstellen" ON public.mood_logs FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Eigene Mood-Logs bearbeiten" ON public.mood_logs FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Eigene Mood-Logs löschen" ON public.mood_logs FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- FERTIG! ✅
-- Die Datenbank ist jetzt vollständig eingerichtet.
-- ============================================
