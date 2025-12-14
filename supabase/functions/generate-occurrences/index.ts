// Edge Function: generate-occurrences
// Generates todo occurrences from RRULE for a date range

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { RRule, RRuleSet } from "https://esm.sh/rrule@2.7.2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface GenerateRequest {
  todo_id: string;
  rrule: string;
  start_date: string; // ISO date string
  end_date: string; // ISO date string
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Get authorization header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { todo_id, rrule, start_date, end_date }: GenerateRequest = await req.json();

    if (!todo_id || !rrule || !start_date || !end_date) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: todo_id, rrule, start_date, end_date" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Initialize Supabase client with user's auth
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    // Get the user
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Verify the todo belongs to the user
    const { data: todo, error: todoError } = await supabase
      .from("todos")
      .select("id, user_id")
      .eq("id", todo_id)
      .single();

    if (todoError || !todo || todo.user_id !== user.id) {
      return new Response(
        JSON.stringify({ error: "Todo not found or unauthorized" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Parse the RRULE and generate occurrences
    const startDt = new Date(start_date);
    const endDt = new Date(end_date);
    
    let rule: RRule;
    try {
      rule = RRule.fromString(rrule);
    } catch (e) {
      return new Response(
        JSON.stringify({ error: "Invalid RRULE format" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Get occurrences within the date range
    const occurrences = rule.between(startDt, endDt, true);

    // Get existing occurrences to avoid duplicates
    const { data: existingOccurrences, error: existingError } = await supabase
      .from("todo_occurrences")
      .select("occurrence_date")
      .eq("todo_id", todo_id)
      .gte("occurrence_date", start_date)
      .lte("occurrence_date", end_date);

    if (existingError) {
      console.error("Error fetching existing occurrences:", existingError);
    }

    const existingDates = new Set(
      (existingOccurrences || []).map((o: any) => o.occurrence_date)
    );

    // Filter out dates that already have occurrences
    const newOccurrences = occurrences.filter((date) => {
      const dateStr = date.toISOString().split("T")[0];
      return !existingDates.has(dateStr);
    });

    // Create new occurrence records
    if (newOccurrences.length > 0) {
      const occurrenceRecords = newOccurrences.map((date) => ({
        todo_id: todo_id,
        user_id: user.id,
        occurrence_date: date.toISOString().split("T")[0],
        is_completed: false,
      }));

      const { data: inserted, error: insertError } = await supabase
        .from("todo_occurrences")
        .insert(occurrenceRecords)
        .select();

      if (insertError) {
        console.error("Error inserting occurrences:", insertError);
        return new Response(
          JSON.stringify({ error: "Failed to create occurrences" }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      return new Response(
        JSON.stringify({
          message: `Created ${inserted.length} new occurrences`,
          occurrences: inserted,
          skipped: existingDates.size,
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        message: "No new occurrences to create",
        skipped: existingDates.size,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error in generate-occurrences:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
