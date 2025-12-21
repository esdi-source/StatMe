-- ============================================================================
-- EVENT LOG SYSTEM - Zentrales Datenerfassungssystem
-- ============================================================================
-- Append-only Event-Log für alle Widget-Daten
-- Ermöglicht langfristige Speicherung, Statistiken und Backups
-- ============================================================================

-- Event-Typen Enum
CREATE TYPE event_type AS ENUM (
  'create',      -- Neuer Eintrag erstellt
  'update',      -- Eintrag aktualisiert
  'delete',      -- Eintrag gelöscht
  'complete',    -- Aufgabe/Gewohnheit abgeschlossen
  'skip',        -- Eintrag übersprungen
  'log',         -- Allgemeiner Log-Eintrag (z.B. Stimmung, Wasser)
  'start',       -- Session gestartet (Timer, Sport)
  'end',         -- Session beendet
  'import',      -- Daten importiert
  'migration'    -- Daten aus Legacy-System migriert
);

-- Haupt Event-Log Tabelle (Append-Only!)
CREATE TABLE IF NOT EXISTS event_log (
  -- Primärschlüssel
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Benutzer-Referenz (PFLICHT)
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Widget-Identifikation (generisch)
  widget_name TEXT NOT NULL,           -- z.B. 'mood', 'water', 'sport', 'school_grades'
  
  -- Event-Typ
  event_type event_type NOT NULL DEFAULT 'log',
  
  -- Zeitstempel
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Referenz-ID (optional, für Updates/Deletes)
  reference_id TEXT,                   -- Original-ID des betroffenen Eintrags
  
  -- Payload (JSON, beliebige Struktur)
  payload JSONB NOT NULL DEFAULT '{}',
  
  -- Metadaten
  client_timestamp TIMESTAMPTZ,        -- Zeitstempel vom Client (für Offline-Sync)
  client_version TEXT,                 -- App-Version für Debugging
  
  -- Erstellungszeitpunkt (Server)
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- INDIZES für Performance
-- ============================================================================

-- Schnelle Abfragen pro Benutzer und Zeit
CREATE INDEX idx_event_log_user_time ON event_log (user_id, timestamp DESC);

-- Schnelle Abfragen pro Widget
CREATE INDEX idx_event_log_user_widget ON event_log (user_id, widget_name, timestamp DESC);

-- Schnelle Abfragen für Statistik (Zeitraum + Widget)
CREATE INDEX idx_event_log_stats ON event_log (user_id, widget_name, event_type, timestamp);

-- GIN-Index für JSONB-Suche im Payload
CREATE INDEX idx_event_log_payload ON event_log USING GIN (payload);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE event_log ENABLE ROW LEVEL SECURITY;

-- Benutzer können nur eigene Events sehen
CREATE POLICY "Users can view own events"
  ON event_log FOR SELECT
  USING (auth.uid() = user_id);

-- Benutzer können nur eigene Events einfügen
CREATE POLICY "Users can insert own events"
  ON event_log FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- KEINE UPDATE/DELETE Policies (Append-Only!)
-- Events werden NIEMALS geändert oder gelöscht

-- ============================================================================
-- HILFSFUNKTIONEN
-- ============================================================================

-- Funktion: Event einfügen (vereinfacht)
CREATE OR REPLACE FUNCTION log_event(
  p_user_id UUID,
  p_widget_name TEXT,
  p_event_type event_type,
  p_payload JSONB,
  p_reference_id TEXT DEFAULT NULL,
  p_client_timestamp TIMESTAMPTZ DEFAULT NULL,
  p_client_version TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_event_id UUID;
BEGIN
  INSERT INTO event_log (
    user_id,
    widget_name,
    event_type,
    payload,
    reference_id,
    client_timestamp,
    client_version
  ) VALUES (
    p_user_id,
    p_widget_name,
    p_event_type,
    p_payload,
    p_reference_id,
    COALESCE(p_client_timestamp, NOW()),
    p_client_version
  ) RETURNING id INTO v_event_id;
  
  RETURN v_event_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Funktion: Statistik für Zeitraum abrufen
CREATE OR REPLACE FUNCTION get_widget_stats(
  p_user_id UUID,
  p_widget_name TEXT,
  p_start_date DATE,
  p_end_date DATE
) RETURNS TABLE (
  event_date DATE,
  event_count BIGINT,
  event_types TEXT[]
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    DATE(timestamp) as event_date,
    COUNT(*) as event_count,
    ARRAY_AGG(DISTINCT event_type::TEXT) as event_types
  FROM event_log
  WHERE user_id = p_user_id
    AND widget_name = p_widget_name
    AND timestamp >= p_start_date
    AND timestamp < p_end_date + INTERVAL '1 day'
  GROUP BY DATE(timestamp)
  ORDER BY event_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Funktion: Alle Widgets eines Benutzers mit letztem Event
CREATE OR REPLACE FUNCTION get_user_widgets(p_user_id UUID) 
RETURNS TABLE (
  widget_name TEXT,
  event_count BIGINT,
  first_event TIMESTAMPTZ,
  last_event TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    el.widget_name,
    COUNT(*) as event_count,
    MIN(el.timestamp) as first_event,
    MAX(el.timestamp) as last_event
  FROM event_log el
  WHERE el.user_id = p_user_id
  GROUP BY el.widget_name
  ORDER BY last_event DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Funktion: Korrelation zwischen zwei Widgets berechnen
CREATE OR REPLACE FUNCTION get_widget_correlation(
  p_user_id UUID,
  p_widget_a TEXT,
  p_widget_b TEXT,
  p_days INTEGER DEFAULT 30
) RETURNS TABLE (
  event_date DATE,
  widget_a_value NUMERIC,
  widget_b_value NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  WITH widget_a_data AS (
    SELECT 
      DATE(timestamp) as event_date,
      AVG((payload->>'value')::NUMERIC) as avg_value
    FROM event_log
    WHERE user_id = p_user_id
      AND widget_name = p_widget_a
      AND timestamp >= CURRENT_DATE - p_days
      AND payload ? 'value'
    GROUP BY DATE(timestamp)
  ),
  widget_b_data AS (
    SELECT 
      DATE(timestamp) as event_date,
      AVG((payload->>'value')::NUMERIC) as avg_value
    FROM event_log
    WHERE user_id = p_user_id
      AND widget_name = p_widget_b
      AND timestamp >= CURRENT_DATE - p_days
      AND payload ? 'value'
    GROUP BY DATE(timestamp)
  )
  SELECT 
    COALESCE(a.event_date, b.event_date) as event_date,
    a.avg_value as widget_a_value,
    b.avg_value as widget_b_value
  FROM widget_a_data a
  FULL OUTER JOIN widget_b_data b ON a.event_date = b.event_date
  ORDER BY event_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- EXPORT VIEWS
-- ============================================================================

-- View: Alle Events eines Benutzers (für Export)
CREATE OR REPLACE VIEW user_events_export AS
SELECT 
  id,
  widget_name,
  event_type,
  timestamp,
  reference_id,
  payload,
  client_timestamp,
  created_at
FROM event_log
WHERE user_id = auth.uid();

-- ============================================================================
-- KOMMENTARE
-- ============================================================================

COMMENT ON TABLE event_log IS 'Zentrales Event-Log für alle Widget-Daten. Append-Only!';
COMMENT ON COLUMN event_log.widget_name IS 'Name des Widgets, z.B. mood, water, sport, school_grades';
COMMENT ON COLUMN event_log.event_type IS 'Art des Events: create, update, delete, complete, skip, log, start, end';
COMMENT ON COLUMN event_log.payload IS 'JSON-Daten des Events (widget-spezifisch)';
COMMENT ON COLUMN event_log.reference_id IS 'ID des ursprünglichen Eintrags (für Updates/Deletes)';
