-- Erweitere micro_widgets Tabelle um fehlende Spalten
-- Die App erwartet type, target_count, frequency, period_start

-- Füge type Spalte hinzu (reading, meditation, sport, water, custom)
ALTER TABLE public.micro_widgets 
ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'custom';

-- Füge target_count Spalte hinzu (wie oft pro Periode)
ALTER TABLE public.micro_widgets 
ADD COLUMN IF NOT EXISTS target_count INTEGER DEFAULT 1;

-- Füge frequency Spalte hinzu (daily, weekly, monthly)
ALTER TABLE public.micro_widgets 
ADD COLUMN IF NOT EXISTS frequency TEXT DEFAULT 'weekly';

-- Füge period_start Spalte hinzu (Start der aktuellen Periode)
ALTER TABLE public.micro_widgets 
ADD COLUMN IF NOT EXISTS period_start TIMESTAMPTZ DEFAULT NOW();

-- Erstelle Index für type für schnellere Abfragen
CREATE INDEX IF NOT EXISTS idx_micro_widgets_type ON public.micro_widgets(type);
