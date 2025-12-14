# 🚀 Supabase Setup-Anleitung für StatMe

Diese Anleitung erklärt, wie du StatMe mit Supabase verbindest, um die App im Produktionsmodus zu betreiben.

## Inhaltsverzeichnis

1. [Supabase-Projekt erstellen](#1-supabase-projekt-erstellen)
2. [Datenbank-Schema einrichten](#2-datenbank-schema-einrichten)
3. [Row Level Security (RLS) konfigurieren](#3-row-level-security-rls-konfigurieren)
4. [Auth-Einstellungen anpassen](#4-auth-einstellungen-anpassen)
5. [API-Keys kopieren](#5-api-keys-kopieren)
6. [App konfigurieren](#6-app-konfigurieren)
7. [Edge Functions (optional)](#7-edge-functions-optional)
8. [Deployment](#8-deployment)

---

## 1. Supabase-Projekt erstellen

1. Gehe zu [supabase.com](https://supabase.com) und erstelle einen Account
2. Klicke auf "New Project"
3. Wähle deine Organisation oder erstelle eine neue
4. Fülle aus:
   - **Name**: `statme` (oder dein Wunschname)
   - **Database Password**: Erstelle ein sicheres Passwort (speichere es!)
   - **Region**: Wähle eine Region nahe deinen Nutzern (z.B. `eu-central-1` für Deutschland)
5. Klicke auf "Create new project" und warte bis das Projekt erstellt ist (~2 Minuten)

---

## 2. Datenbank-Schema einrichten

### Option A: Über SQL Editor

1. Gehe in deinem Supabase-Dashboard zu **SQL Editor**
2. Klicke auf "New query"
3. Kopiere den Inhalt von `supabase/migrations/20240101000000_initial_schema.sql` und führe ihn aus:

```sql
-- User Profiles
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Settings
CREATE TABLE IF NOT EXISTS settings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE UNIQUE NOT NULL,
  daily_calorie_goal INTEGER DEFAULT 2000,
  daily_water_goal INTEGER DEFAULT 2500,
  daily_steps_goal INTEGER DEFAULT 10000,
  sleep_goal_hours DOUBLE PRECISION DEFAULT 8.0,
  notifications_enabled BOOLEAN DEFAULT true,
  dark_mode BOOLEAN DEFAULT false,
  language TEXT DEFAULT 'de',
  theme_color_value INTEGER DEFAULT 4283215696,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Todos (wiederkehrend oder einmalig)
CREATE TABLE IF NOT EXISTS todos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  recurrence_type TEXT DEFAULT 'once', -- once, daily, weekly, monthly
  recurrence_days INTEGER[] DEFAULT '{}',
  start_date DATE,
  end_date DATE,
  time_of_day TIME,
  reminder_minutes INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Todo Occurrences (einzelne Vorkommen eines Todos)
CREATE TABLE IF NOT EXISTS todo_occurrences (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  todo_id UUID REFERENCES todos(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  date DATE NOT NULL,
  is_completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Food Logs
CREATE TABLE IF NOT EXISTS food_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  product_name TEXT NOT NULL,
  barcode TEXT,
  calories DOUBLE PRECISION NOT NULL,
  grams DOUBLE PRECISION NOT NULL,
  proteins DOUBLE PRECISION,
  carbohydrates DOUBLE PRECISION,
  fats DOUBLE PRECISION,
  date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Water Logs
CREATE TABLE IF NOT EXISTS water_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  amount_ml INTEGER NOT NULL,
  date DATE NOT NULL,
  time TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Steps Logs
CREATE TABLE IF NOT EXISTS steps_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  steps INTEGER NOT NULL,
  date DATE NOT NULL,
  source TEXT DEFAULT 'manual',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Sleep Logs
CREATE TABLE IF NOT EXISTS sleep_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  sleep_start TIMESTAMPTZ NOT NULL,
  sleep_end TIMESTAMPTZ NOT NULL,
  quality INTEGER CHECK (quality >= 1 AND quality <= 10),
  notes TEXT,
  date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Mood Logs
CREATE TABLE IF NOT EXISTS mood_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  mood_level INTEGER NOT NULL CHECK (mood_level >= 1 AND mood_level <= 10),
  energy_level INTEGER CHECK (energy_level >= 1 AND energy_level <= 10),
  notes TEXT,
  tags TEXT[],
  date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trigger für automatisches Profil-Erstellen bei Registrierung
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, display_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1))
  );
  
  INSERT INTO public.settings (user_id)
  VALUES (NEW.id);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger aktivieren
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Indizes für bessere Performance
CREATE INDEX IF NOT EXISTS idx_todos_user_id ON todos(user_id);
CREATE INDEX IF NOT EXISTS idx_todo_occurrences_user_date ON todo_occurrences(user_id, date);
CREATE INDEX IF NOT EXISTS idx_food_logs_user_date ON food_logs(user_id, date);
CREATE INDEX IF NOT EXISTS idx_water_logs_user_date ON water_logs(user_id, date);
CREATE INDEX IF NOT EXISTS idx_steps_logs_user_date ON steps_logs(user_id, date);
CREATE INDEX IF NOT EXISTS idx_sleep_logs_user_date ON sleep_logs(user_id, date);
CREATE INDEX IF NOT EXISTS idx_mood_logs_user_date ON mood_logs(user_id, date);
```

### Option B: Über Supabase CLI

```bash
cd /Users/noahsupenkamper/Desktop/StatMe
npx supabase link --project-ref DEIN_PROJECT_REF
npx supabase db push
```

---

## 3. Row Level Security (RLS) konfigurieren

Führe im SQL Editor aus:

```sql
-- RLS aktivieren
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE todos ENABLE ROW LEVEL SECURITY;
ALTER TABLE todo_occurrences ENABLE ROW LEVEL SECURITY;
ALTER TABLE food_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE water_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE steps_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE sleep_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE mood_logs ENABLE ROW LEVEL SECURITY;

-- Policies für Profiles
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- Policies für Settings
CREATE POLICY "Users can view own settings" ON settings
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own settings" ON settings
  FOR UPDATE USING (auth.uid() = user_id);

-- Generische Policies für alle Log-Tabellen
DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOREACH tbl IN ARRAY ARRAY['todos', 'todo_occurrences', 'food_logs', 'water_logs', 'steps_logs', 'sleep_logs', 'mood_logs']
  LOOP
    EXECUTE format('
      CREATE POLICY "Users can view own %I" ON %I
        FOR SELECT USING (auth.uid() = user_id);
      
      CREATE POLICY "Users can insert own %I" ON %I
        FOR INSERT WITH CHECK (auth.uid() = user_id);
      
      CREATE POLICY "Users can update own %I" ON %I
        FOR UPDATE USING (auth.uid() = user_id);
      
      CREATE POLICY "Users can delete own %I" ON %I
        FOR DELETE USING (auth.uid() = user_id);
    ', tbl, tbl, tbl, tbl, tbl, tbl, tbl, tbl);
  END LOOP;
END $$;
```

---

## 4. Auth-Einstellungen anpassen

1. Gehe zu **Authentication > Providers**
2. Aktiviere **Email** Provider (standardmäßig aktiviert)
3. Unter **Email Templates** kannst du die E-Mails anpassen

### Optionale OAuth Provider:

1. **Google**: 
   - Erstelle OAuth-Credentials in der [Google Cloud Console](https://console.cloud.google.com)
   - Füge Client ID und Secret in Supabase ein
   
2. **Apple**:
   - Konfiguriere Sign in with Apple in der Apple Developer Console
   - Füge die Credentials in Supabase ein

---

## 5. API-Keys kopieren

1. Gehe zu **Project Settings > API**
2. Kopiere folgende Werte:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public Key**: `eyJ...` (der lange Key)

---

## 6. App konfigurieren

### Schritt 1: `.env` Datei aktualisieren

Öffne `/Users/noahsupenkamper/Desktop/StatMe/.env` und ändere:

```env
# =============================================
# StatMe Environment Configuration
# =============================================

# Demo Mode - set to 'false' for production
DEMO_MODE=false

# Supabase Configuration
SUPABASE_URL=https://DEIN_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=dein_anon_key_hier

# Optional: OpenFoodFacts API (funktioniert auch ohne Key)
# OPENFOODFACTS_USER_AGENT=StatMe/1.0

# =============================================
```

### Schritt 2: App neu starten

```bash
cd /Users/noahsupenkamper/Desktop/StatMe
flutter clean
flutter pub get
flutter run -d chrome  # oder macos, windows, linux
```

---

## 7. Edge Functions (optional)

Für erweiterte Funktionen wie automatische Todo-Generierung:

### Edge Function deployen

```bash
cd /Users/noahsupenkamper/Desktop/StatMe
npx supabase functions deploy generate-occurrences
```

### Cron Job einrichten (in Supabase SQL Editor)

```sql
SELECT cron.schedule(
  'generate-daily-occurrences',
  '0 0 * * *', -- Täglich um Mitternacht
  $$
  SELECT net.http_post(
    url := 'https://DEIN_PROJECT_REF.supabase.co/functions/v1/generate-occurrences',
    headers := '{"Authorization": "Bearer DEIN_SERVICE_ROLE_KEY"}'::jsonb
  );
  $$
);
```

---

## 8. Deployment

### GitHub Pages (Web)

Die App ist bereits für GitHub Pages konfiguriert. Nach der Supabase-Konfiguration:

```bash
cd /Users/noahsupenkamper/Desktop/StatMe
git add .
git commit -m "feat: Add Supabase production configuration"
git push
```

GitHub Actions baut und deployed automatisch.

### Native Apps

Für iOS/Android benötigst du zusätzliche Konfiguration:

#### iOS (macOS erforderlich)

```bash
flutter build ios --release
# Dann über Xcode archivieren und zum App Store hochladen
```

#### Android

```bash
flutter build apk --release
# APK liegt in build/app/outputs/flutter-apk/
```

---

## 🔒 Sicherheits-Checkliste

- [ ] RLS ist für alle Tabellen aktiviert
- [ ] Service Role Key ist **niemals** im Frontend verwendet
- [ ] `.env` ist in `.gitignore` eingetragen
- [ ] Email-Bestätigung ist aktiviert
- [ ] Rate Limiting ist konfiguriert

---

## 🐛 Troubleshooting

### "Permission denied" Fehler
→ Überprüfe die RLS-Policies im SQL Editor

### Auth-Fehler
→ Überprüfe, ob die Supabase-URL und der Anon-Key korrekt sind

### Daten werden nicht gespeichert
→ Stelle sicher, dass `DEMO_MODE=false` in der `.env` gesetzt ist

### Edge Functions funktionieren nicht
→ Überprüfe die Logs unter **Edge Functions > Logs** im Dashboard

---

## 📚 Weiterführende Ressourcen

- [Supabase Dokumentation](https://supabase.com/docs)
- [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Edge Functions Guide](https://supabase.com/docs/guides/functions)

---

Bei Fragen oder Problemen: Erstelle ein Issue im GitHub Repository!
