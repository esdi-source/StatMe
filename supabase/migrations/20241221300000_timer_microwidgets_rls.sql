-- RLS Policies für Timer und MicroWidgets
-- Stellt sicher, dass User nur ihre eigenen Daten sehen

-- ============================================
-- TIMER SESSIONS POLICIES
-- ============================================
ALTER TABLE public.timer_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own timer sessions" ON public.timer_sessions;
CREATE POLICY "Users can view own timer sessions"
    ON public.timer_sessions FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create own timer sessions" ON public.timer_sessions;
CREATE POLICY "Users can create own timer sessions"
    ON public.timer_sessions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own timer sessions" ON public.timer_sessions;
CREATE POLICY "Users can update own timer sessions"
    ON public.timer_sessions FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own timer sessions" ON public.timer_sessions;
CREATE POLICY "Users can delete own timer sessions"
    ON public.timer_sessions FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- MICRO WIDGETS POLICIES
-- ============================================
ALTER TABLE public.micro_widgets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own micro widgets" ON public.micro_widgets;
CREATE POLICY "Users can view own micro widgets"
    ON public.micro_widgets FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create own micro widgets" ON public.micro_widgets;
CREATE POLICY "Users can create own micro widgets"
    ON public.micro_widgets FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own micro widgets" ON public.micro_widgets;
CREATE POLICY "Users can update own micro widgets"
    ON public.micro_widgets FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own micro widgets" ON public.micro_widgets;
CREATE POLICY "Users can delete own micro widgets"
    ON public.micro_widgets FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- MICRO WIDGET COMPLETIONS POLICIES
-- ============================================
ALTER TABLE public.micro_widget_completions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own micro widget completions" ON public.micro_widget_completions;
CREATE POLICY "Users can view own micro widget completions"
    ON public.micro_widget_completions FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create own micro widget completions" ON public.micro_widget_completions;
CREATE POLICY "Users can create own micro widget completions"
    ON public.micro_widget_completions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own micro widget completions" ON public.micro_widget_completions;
CREATE POLICY "Users can update own micro widget completions"
    ON public.micro_widget_completions FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own micro widget completions" ON public.micro_widget_completions;
CREATE POLICY "Users can delete own micro widget completions"
    ON public.micro_widget_completions FOR DELETE
    USING (auth.uid() = user_id);
