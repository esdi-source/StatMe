// Edge Function: backfill-book-covers
// Batch-Job für nachträgliche Cover-Ermittlung

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface BackfillResult {
  processed: number;
  success: number;
  failed: number;
  skipped: number;
  details: Array<{
    bookId: string;
    title: string;
    status: "success" | "failed" | "skipped";
    coverUrl?: string;
    error?: string;
  }>;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json().catch(() => ({}));
    const {
      limit = 50,
      skip_recent_failures = true,
      min_days_since_attempt = 7,
      user_id = null,
    } = body;

    // Initialize Supabase
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Build query for books needing covers
    let query = supabase
      .from("books")
      .select("id, title, author, isbn, isbn10, isbn13, google_books_id, cover_url, cover_status, last_cover_attempt_at, cover_attempts")
      .or("cover_status.is.null,cover_status.eq.pending,cover_status.eq.missing")
      .order("added_at", { ascending: false })
      .limit(limit);

    // Filter by user if specified
    if (user_id) {
      query = query.eq("user_id", user_id);
    }

    // Skip recent failures if enabled
    if (skip_recent_failures) {
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - min_days_since_attempt);
      query = query.or(
        `last_cover_attempt_at.is.null,last_cover_attempt_at.lt.${cutoffDate.toISOString()}`
      );
    }

    const { data: books, error: queryError } = await query;

    if (queryError) {
      console.error("Query error:", queryError);
      return new Response(
        JSON.stringify({ error: "Failed to query books" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (!books || books.length === 0) {
      return new Response(
        JSON.stringify({
          message: "No books need cover fetching",
          processed: 0,
          success: 0,
          failed: 0,
          skipped: 0,
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const result: BackfillResult = {
      processed: 0,
      success: 0,
      failed: 0,
      skipped: 0,
      details: [],
    };

    // Process books with rate limiting
    for (const book of books) {
      result.processed++;

      // Skip if too many attempts already
      if (book.cover_attempts && book.cover_attempts >= 5) {
        result.skipped++;
        result.details.push({
          bookId: book.id,
          title: book.title,
          status: "skipped",
          error: "Max attempts reached",
        });
        continue;
      }

      // Call fetch-book-cover function
      try {
        const fetchUrl = `${supabaseUrl}/functions/v1/fetch-book-cover`;
        const response = await fetch(fetchUrl, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${supabaseServiceKey}`,
          },
          body: JSON.stringify({
            book_id: book.id,
            force_refresh: false,
          }),
        });

        const fetchResult = await response.json();

        if (fetchResult.success) {
          result.success++;
          result.details.push({
            bookId: book.id,
            title: book.title,
            status: "success",
            coverUrl: fetchResult.coverUrl,
          });
        } else {
          result.failed++;
          result.details.push({
            bookId: book.id,
            title: book.title,
            status: "failed",
            error: fetchResult.error,
          });
        }
      } catch (e) {
        result.failed++;
        result.details.push({
          bookId: book.id,
          title: book.title,
          status: "failed",
          error: e instanceof Error ? e.message : "Unknown error",
        });
      }

      // Rate limiting: wait between requests
      await new Promise((resolve) => setTimeout(resolve, 500));
    }

    // Log backfill run
    await supabase.from("cover_fetch_logs").insert({
      isbn_searched: null,
      title_searched: `Backfill: ${result.processed} books`,
      author_searched: null,
      sources_tried: ["backfill"],
      source_found: null,
      cover_url_found: null,
      duration_ms: null,
      triggered_by: "backfill",
      raw_response: result,
    });

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Error in backfill-book-covers:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
