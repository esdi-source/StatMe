-- Book Covers Migration
-- Erstellt Tabellen und Strukturen für priorisierte Cover-Ermittlung

-- ============================================
-- BOOKS TABLE (falls noch nicht vorhanden)
-- ============================================
CREATE TABLE IF NOT EXISTS public.books (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    author TEXT,
    cover_url TEXT,
    google_books_id TEXT,
    isbn TEXT,
    isbn10 TEXT,
    isbn13 TEXT,
    status TEXT NOT NULL DEFAULT 'want_to_read' CHECK (status IN ('want_to_read', 'reading', 'finished')),
    rating JSONB,
    added_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    finished_at TIMESTAMPTZ,
    page_count INTEGER,
    
    -- Cover-Status Felder
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

-- ============================================
-- BOOK COVERS TABLE
-- Speichert alle Cover-Versuche und -Quellen
-- ============================================
CREATE TABLE IF NOT EXISTS public.book_covers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    book_id UUID NOT NULL REFERENCES public.books(id) ON DELETE CASCADE,
    
    -- Quelle und Identifikation
    source TEXT NOT NULL CHECK (source IN (
        'google_books', 
        'open_library', 
        'isbn_db',
        'world_cat',
        'bing_image',
        'google_image',
        'user_upload'
    )),
    source_id TEXT,                -- ID bei der Quelle (z.B. Google Books ID)
    source_url TEXT,               -- Original-URL des Covers
    
    -- Lokale Speicherung
    storage_path TEXT,             -- Pfad in Supabase Storage
    cdn_url TEXT,                  -- Ausgelieferter CDN-URL
    
    -- Metadaten
    width INTEGER,                 -- Bildbreite in Pixel
    height INTEGER,                -- Bildhöhe in Pixel
    file_size INTEGER,             -- Dateigröße in Bytes
    mime_type TEXT,                -- z.B. 'image/jpeg', 'image/webp'
    
    -- Status
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'ok', 'error', 'invalid')),
    error_message TEXT,
    
    -- Matching-Qualität
    match_confidence DOUBLE PRECISION, -- 0.0 - 1.0 für Fuzzy-Matching
    match_method TEXT,             -- 'isbn_exact', 'isbn_converted', 'title_author_fuzzy'
    
    -- Audit
    attempts INTEGER DEFAULT 0,
    fetched_at TIMESTAMPTZ,
    raw_response JSONB,            -- Original API-Response für Debugging
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Ein Buch kann nur ein Cover pro Quelle haben
    UNIQUE(book_id, source)
);

CREATE INDEX idx_book_covers_book_id ON public.book_covers(book_id);
CREATE INDEX idx_book_covers_status ON public.book_covers(status);
CREATE INDEX idx_book_covers_source ON public.book_covers(source);

-- ============================================
-- COVER FETCH LOGS TABLE
-- Für Admin-Dashboard und Debugging
-- ============================================
CREATE TABLE IF NOT EXISTS public.cover_fetch_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    book_id UUID REFERENCES public.books(id) ON DELETE SET NULL,
    
    -- Request-Details
    isbn_searched TEXT,
    title_searched TEXT,
    author_searched TEXT,
    
    -- Ergebnis
    sources_tried TEXT[],          -- ['google_books', 'open_library', ...]
    source_found TEXT,             -- Welche Quelle erfolgreich war
    cover_url_found TEXT,
    
    -- Timing
    duration_ms INTEGER,
    
    -- Fehler
    error_code TEXT,
    error_message TEXT,
    
    -- Kontext
    triggered_by TEXT CHECK (triggered_by IN ('auto', 'user_retry', 'backfill', 'add_book')),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_cover_fetch_logs_book_id ON public.cover_fetch_logs(book_id);
CREATE INDEX idx_cover_fetch_logs_created_at ON public.cover_fetch_logs(created_at);
CREATE INDEX idx_cover_fetch_logs_error_code ON public.cover_fetch_logs(error_code);

-- ============================================
-- RATE LIMIT TRACKING
-- ============================================
CREATE TABLE IF NOT EXISTS public.api_rate_limits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    api_name TEXT NOT NULL UNIQUE,
    requests_count INTEGER DEFAULT 0,
    window_start TIMESTAMPTZ DEFAULT NOW(),
    window_duration_seconds INTEGER DEFAULT 60,
    max_requests INTEGER DEFAULT 100,
    last_request_at TIMESTAMPTZ,
    backoff_until TIMESTAMPTZ,      -- Wenn 429 erhalten, bis wann warten
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Initiale Rate-Limits für APIs
INSERT INTO public.api_rate_limits (api_name, max_requests, window_duration_seconds)
VALUES 
    ('google_books', 100, 60),
    ('open_library', 50, 60),
    ('isbn_db', 10, 60)
ON CONFLICT (api_name) DO NOTHING;

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Funktion: ISBN normalisieren (Striche entfernen, nur Ziffern/X)
CREATE OR REPLACE FUNCTION normalize_isbn(isbn_input TEXT)
RETURNS TEXT AS $$
BEGIN
    IF isbn_input IS NULL THEN
        RETURN NULL;
    END IF;
    -- Entferne alles außer Ziffern und X (für ISBN-10 Prüfziffer)
    RETURN UPPER(REGEXP_REPLACE(isbn_input, '[^0-9Xx]', '', 'g'));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Funktion: ISBN-10 zu ISBN-13 konvertieren
CREATE OR REPLACE FUNCTION isbn10_to_isbn13(isbn10 TEXT)
RETURNS TEXT AS $$
DECLARE
    normalized TEXT;
    isbn13_base TEXT;
    check_digit INTEGER;
    sum INTEGER := 0;
    i INTEGER;
    digit INTEGER;
BEGIN
    normalized := normalize_isbn(isbn10);
    
    IF normalized IS NULL OR LENGTH(normalized) != 10 THEN
        RETURN NULL;
    END IF;
    
    -- ISBN-13 Basis: 978 + erste 9 Ziffern der ISBN-10
    isbn13_base := '978' || SUBSTRING(normalized FROM 1 FOR 9);
    
    -- Berechne Prüfziffer für ISBN-13
    FOR i IN 1..12 LOOP
        digit := CAST(SUBSTRING(isbn13_base FROM i FOR 1) AS INTEGER);
        IF i % 2 = 0 THEN
            sum := sum + digit * 3;
        ELSE
            sum := sum + digit;
        END IF;
    END LOOP;
    
    check_digit := (10 - (sum % 10)) % 10;
    
    RETURN isbn13_base || check_digit::TEXT;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Funktion: ISBN-13 zu ISBN-10 konvertieren
CREATE OR REPLACE FUNCTION isbn13_to_isbn10(isbn13 TEXT)
RETURNS TEXT AS $$
DECLARE
    normalized TEXT;
    isbn10_base TEXT;
    check_digit TEXT;
    sum INTEGER := 0;
    i INTEGER;
    digit INTEGER;
    remainder INTEGER;
BEGIN
    normalized := normalize_isbn(isbn13);
    
    IF normalized IS NULL OR LENGTH(normalized) != 13 THEN
        RETURN NULL;
    END IF;
    
    -- Nur 978-Präfix kann zu ISBN-10 konvertiert werden
    IF SUBSTRING(normalized FROM 1 FOR 3) != '978' THEN
        RETURN NULL;
    END IF;
    
    -- ISBN-10 Basis: Ziffern 4-12 der ISBN-13
    isbn10_base := SUBSTRING(normalized FROM 4 FOR 9);
    
    -- Berechne Prüfziffer für ISBN-10
    FOR i IN 1..9 LOOP
        digit := CAST(SUBSTRING(isbn10_base FROM i FOR 1) AS INTEGER);
        sum := sum + digit * (10 - i + 1);
    END LOOP;
    
    remainder := (11 - (sum % 11)) % 11;
    
    IF remainder = 10 THEN
        check_digit := 'X';
    ELSE
        check_digit := remainder::TEXT;
    END IF;
    
    RETURN isbn10_base || check_digit;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Funktion: Beste Cover-URL für ein Buch ermitteln
CREATE OR REPLACE FUNCTION get_best_cover_url(p_book_id UUID)
RETURNS TEXT AS $$
DECLARE
    cover_url TEXT;
BEGIN
    -- Priorität: user_upload > google_books > open_library > andere
    SELECT bc.cdn_url INTO cover_url
    FROM public.book_covers bc
    WHERE bc.book_id = p_book_id 
      AND bc.status = 'ok'
      AND bc.cdn_url IS NOT NULL
    ORDER BY 
        CASE bc.source 
            WHEN 'user_upload' THEN 1
            WHEN 'google_books' THEN 2
            WHEN 'open_library' THEN 3
            WHEN 'isbn_db' THEN 4
            ELSE 5
        END,
        bc.created_at DESC
    LIMIT 1;
    
    RETURN cover_url;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================
-- TRIGGERS
-- ============================================

-- updated_at Trigger für book_covers
CREATE TRIGGER update_book_covers_updated_at 
    BEFORE UPDATE ON public.book_covers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- updated_at Trigger für api_rate_limits
CREATE TRIGGER update_api_rate_limits_updated_at 
    BEFORE UPDATE ON public.api_rate_limits
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger: ISBN normalisieren beim Einfügen/Aktualisieren eines Buches
CREATE OR REPLACE FUNCTION normalize_book_isbns()
RETURNS TRIGGER AS $$
BEGIN
    -- Normalisiere ISBN
    NEW.isbn := normalize_isbn(NEW.isbn);
    
    -- Setze isbn10 und isbn13 basierend auf der Länge
    IF NEW.isbn IS NOT NULL THEN
        IF LENGTH(NEW.isbn) = 10 THEN
            NEW.isbn10 := NEW.isbn;
            NEW.isbn13 := isbn10_to_isbn13(NEW.isbn);
        ELSIF LENGTH(NEW.isbn) = 13 THEN
            NEW.isbn13 := NEW.isbn;
            NEW.isbn10 := isbn13_to_isbn10(NEW.isbn);
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER normalize_book_isbns_trigger
    BEFORE INSERT OR UPDATE OF isbn ON public.books
    FOR EACH ROW EXECUTE FUNCTION normalize_book_isbns();

-- ============================================
-- RLS POLICIES
-- ============================================

ALTER TABLE public.books ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.book_covers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cover_fetch_logs ENABLE ROW LEVEL SECURITY;

-- Books: Nutzer können nur eigene Bücher sehen/bearbeiten
CREATE POLICY "Users can view own books" ON public.books
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own books" ON public.books
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own books" ON public.books
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own books" ON public.books
    FOR DELETE USING (auth.uid() = user_id);

-- Book Covers: Nutzer können Cover ihrer Bücher sehen
CREATE POLICY "Users can view covers of own books" ON public.book_covers
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.books 
            WHERE books.id = book_covers.book_id 
            AND books.user_id = auth.uid()
        )
    );

-- Service Role kann alles (für Edge Functions)
CREATE POLICY "Service role full access books" ON public.books
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "Service role full access book_covers" ON public.book_covers
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "Service role full access cover_fetch_logs" ON public.cover_fetch_logs
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- ============================================
-- STORAGE BUCKET (Muss via Supabase Dashboard erstellt werden)
-- ============================================
-- Bucket: book-covers
-- Public: true (für CDN-Zugriff)
-- Allowed MIME types: image/jpeg, image/png, image/webp
-- Max file size: 5MB

COMMENT ON TABLE public.book_covers IS 'Speichert alle Cover-Quellen und -URLs für Bücher. Priorisierte Kaskade: user_upload > google_books > open_library > andere';
COMMENT ON TABLE public.cover_fetch_logs IS 'Audit-Log für alle Cover-Fetch-Versuche. Nützlich für Debugging und Admin-Dashboard.';
COMMENT ON FUNCTION normalize_isbn(TEXT) IS 'Normalisiert ISBN: Entfernt Bindestriche, behält nur Ziffern und X';
COMMENT ON FUNCTION isbn10_to_isbn13(TEXT) IS 'Konvertiert ISBN-10 zu ISBN-13 mit korrekter Prüfzifferberechnung';
COMMENT ON FUNCTION isbn13_to_isbn10(TEXT) IS 'Konvertiert ISBN-13 (nur 978-Präfix) zu ISBN-10';
