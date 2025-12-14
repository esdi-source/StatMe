// Edge Function: identify-product
// Looks up a product by barcode from OpenFoodFacts API and caches it

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface ProductData {
  barcode: string;
  name: string;
  brand: string | null;
  calories_per_100g: number;
  protein_per_100g: number;
  carbs_per_100g: number;
  fat_per_100g: number;
  fiber_per_100g: number;
  sugar_per_100g: number;
  sodium_per_100g: number;
  serving_size_g: number;
  image_url: string | null;
  source: string;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { barcode } = await req.json();

    if (!barcode || typeof barcode !== "string") {
      return new Response(
        JSON.stringify({ error: "Barcode is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Initialize Supabase client with service role
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Check if product is already cached
    const { data: cachedProduct, error: cacheError } = await supabase
      .from("products_cache")
      .select("*")
      .eq("barcode", barcode)
      .single();

    if (cachedProduct && !cacheError) {
      return new Response(
        JSON.stringify({ product: cachedProduct, cached: true }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Fetch from OpenFoodFacts API
    const offResponse = await fetch(
      `https://world.openfoodfacts.org/api/v2/product/${barcode}.json`,
      {
        headers: {
          "User-Agent": "StatMe/1.0 (health tracking app)",
        },
      }
    );

    if (!offResponse.ok) {
      return new Response(
        JSON.stringify({ error: "Failed to fetch product data", barcode }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const offData = await offResponse.json();

    if (offData.status !== 1 || !offData.product) {
      return new Response(
        JSON.stringify({ error: "Product not found", barcode }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const p = offData.product;
    const nutrients = p.nutriments || {};

    // Build product data
    const productData: ProductData = {
      barcode: barcode,
      name: p.product_name || p.product_name_en || "Unknown Product",
      brand: p.brands || null,
      calories_per_100g: nutrients["energy-kcal_100g"] || nutrients["energy-kcal"] || 0,
      protein_per_100g: nutrients.proteins_100g || nutrients.proteins || 0,
      carbs_per_100g: nutrients.carbohydrates_100g || nutrients.carbohydrates || 0,
      fat_per_100g: nutrients.fat_100g || nutrients.fat || 0,
      fiber_per_100g: nutrients.fiber_100g || nutrients.fiber || 0,
      sugar_per_100g: nutrients.sugars_100g || nutrients.sugars || 0,
      sodium_per_100g: (nutrients.sodium_100g || nutrients.sodium || 0) * 1000, // Convert g to mg
      serving_size_g: parseFloat(p.serving_quantity) || 100,
      image_url: p.image_url || p.image_front_url || null,
      source: "openfoodfacts",
    };

    // Cache the product
    const { data: insertedProduct, error: insertError } = await supabase
      .from("products_cache")
      .upsert(productData, { onConflict: "barcode" })
      .select()
      .single();

    if (insertError) {
      console.error("Error caching product:", insertError);
      // Still return the product even if caching fails
      return new Response(
        JSON.stringify({ product: productData, cached: false }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ product: insertedProduct, cached: false }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error in identify-product:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
