-- Row Level Security (RLS) Policies for StatMe
-- All tables are protected so users can only access their own data

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

-- ============================================
-- PROFILES POLICIES
-- ============================================
CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- ============================================
-- TODOS POLICIES
-- ============================================
CREATE POLICY "Users can view own todos"
    ON public.todos FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create own todos"
    ON public.todos FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own todos"
    ON public.todos FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own todos"
    ON public.todos FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- TODO OCCURRENCES POLICIES
-- ============================================
CREATE POLICY "Users can view own todo occurrences"
    ON public.todo_occurrences FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create own todo occurrences"
    ON public.todo_occurrences FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own todo occurrences"
    ON public.todo_occurrences FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own todo occurrences"
    ON public.todo_occurrences FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- PRODUCTS CACHE POLICIES
-- Products are shared/public read, but only service role can write
-- ============================================
CREATE POLICY "Anyone can view products"
    ON public.products_cache FOR SELECT
    USING (true);

-- Note: INSERT/UPDATE handled by Edge Functions with service role key

-- ============================================
-- FOOD LOGS POLICIES
-- ============================================
CREATE POLICY "Users can view own food logs"
    ON public.food_logs FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create own food logs"
    ON public.food_logs FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own food logs"
    ON public.food_logs FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own food logs"
    ON public.food_logs FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- WATER LOGS POLICIES
-- ============================================
CREATE POLICY "Users can view own water logs"
    ON public.water_logs FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create own water logs"
    ON public.water_logs FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own water logs"
    ON public.water_logs FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own water logs"
    ON public.water_logs FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- STEPS LOGS POLICIES
-- ============================================
CREATE POLICY "Users can view own steps logs"
    ON public.steps_logs FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create own steps logs"
    ON public.steps_logs FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own steps logs"
    ON public.steps_logs FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own steps logs"
    ON public.steps_logs FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- SLEEP LOGS POLICIES
-- ============================================
CREATE POLICY "Users can view own sleep logs"
    ON public.sleep_logs FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create own sleep logs"
    ON public.sleep_logs FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own sleep logs"
    ON public.sleep_logs FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own sleep logs"
    ON public.sleep_logs FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- MOOD LOGS POLICIES
-- ============================================
CREATE POLICY "Users can view own mood logs"
    ON public.mood_logs FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create own mood logs"
    ON public.mood_logs FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own mood logs"
    ON public.mood_logs FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own mood logs"
    ON public.mood_logs FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- SETTINGS POLICIES
-- ============================================
CREATE POLICY "Users can view own settings"
    ON public.settings FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update own settings"
    ON public.settings FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Note: INSERT handled by trigger on user creation
