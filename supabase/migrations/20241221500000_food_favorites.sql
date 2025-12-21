-- Food Favorites & Custom Products Migration
-- Allows users to save favorite products and create custom recipes

-- Favorisierte Produkte (aus OpenFoodFacts oder manuell)
CREATE TABLE IF NOT EXISTS favorite_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    oder_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    kcal_per_100g DOUBLE PRECISION NOT NULL,
    protein_per_100g DOUBLE PRECISION,
    carbs_per_100g DOUBLE PRECISION,
    fat_per_100g DOUBLE PRECISION,
    barcode TEXT,
    image_url TEXT,
    default_grams DOUBLE PRECISION,
    use_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Index für schnelle Suche
CREATE INDEX IF NOT EXISTS idx_favorite_products_oder_id ON favorite_products(oder_id);
CREATE INDEX IF NOT EXISTS idx_favorite_products_barcode ON favorite_products(barcode);
CREATE INDEX IF NOT EXISTS idx_favorite_products_name ON favorite_products USING gin(to_tsvector('german', name));

-- Eigene Produkte/Rezepte
CREATE TABLE IF NOT EXISTS custom_food_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    oder_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    kcal_per_100g DOUBLE PRECISION NOT NULL,
    protein_per_100g DOUBLE PRECISION,
    carbs_per_100g DOUBLE PRECISION,
    fat_per_100g DOUBLE PRECISION,
    default_serving_grams DOUBLE PRECISION,
    ingredients JSONB DEFAULT '[]'::jsonb, -- Array von Zutaten
    image_url TEXT,
    is_recipe BOOLEAN DEFAULT false,
    use_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Index für eigene Produkte
CREATE INDEX IF NOT EXISTS idx_custom_food_products_oder_id ON custom_food_products(oder_id);
CREATE INDEX IF NOT EXISTS idx_custom_food_products_name ON custom_food_products USING gin(to_tsvector('german', name));
CREATE INDEX IF NOT EXISTS idx_custom_food_products_is_recipe ON custom_food_products(is_recipe);

-- RLS Policies
ALTER TABLE favorite_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_food_products ENABLE ROW LEVEL SECURITY;

-- Favorite Products RLS
CREATE POLICY "favorite_products_select" ON favorite_products
    FOR SELECT USING (
        oder_id IN (SELECT id FROM orders WHERE user_id = auth.uid())
    );

CREATE POLICY "favorite_products_insert" ON favorite_products
    FOR INSERT WITH CHECK (
        oder_id IN (SELECT id FROM orders WHERE user_id = auth.uid())
    );

CREATE POLICY "favorite_products_update" ON favorite_products
    FOR UPDATE USING (
        oder_id IN (SELECT id FROM orders WHERE user_id = auth.uid())
    );

CREATE POLICY "favorite_products_delete" ON favorite_products
    FOR DELETE USING (
        oder_id IN (SELECT id FROM orders WHERE user_id = auth.uid())
    );

-- Custom Food Products RLS
CREATE POLICY "custom_food_products_select" ON custom_food_products
    FOR SELECT USING (
        oder_id IN (SELECT id FROM orders WHERE user_id = auth.uid())
    );

CREATE POLICY "custom_food_products_insert" ON custom_food_products
    FOR INSERT WITH CHECK (
        oder_id IN (SELECT id FROM orders WHERE user_id = auth.uid())
    );

CREATE POLICY "custom_food_products_update" ON custom_food_products
    FOR UPDATE USING (
        oder_id IN (SELECT id FROM orders WHERE user_id = auth.uid())
    );

CREATE POLICY "custom_food_products_delete" ON custom_food_products
    FOR DELETE USING (
        oder_id IN (SELECT id FROM orders WHERE user_id = auth.uid())
    );

-- Updated_at Trigger
CREATE OR REPLACE FUNCTION update_food_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER favorite_products_updated_at
    BEFORE UPDATE ON favorite_products
    FOR EACH ROW EXECUTE FUNCTION update_food_updated_at();

CREATE TRIGGER custom_food_products_updated_at
    BEFORE UPDATE ON custom_food_products
    FOR EACH ROW EXECUTE FUNCTION update_food_updated_at();

-- Function to increment use count
CREATE OR REPLACE FUNCTION increment_food_use_count(
    table_name TEXT,
    product_id UUID
) RETURNS void AS $$
BEGIN
    IF table_name = 'favorite_products' THEN
        UPDATE favorite_products SET use_count = use_count + 1 WHERE id = product_id;
    ELSIF table_name = 'custom_food_products' THEN
        UPDATE custom_food_products SET use_count = use_count + 1 WHERE id = product_id;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
