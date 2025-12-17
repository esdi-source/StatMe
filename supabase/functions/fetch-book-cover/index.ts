// Edge Function: fetch-book-cover
// Priorisierte Cover-Ermittlung mit Kaskade über mehrere Quellen

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// ============================================
// TYPES
// ============================================

interface BookData {
  id: string;
  title: string;
  author: string | null;
  isbn: string | null;
  isbn10: string | null;
  isbn13: string | null;
  google_books_id: string | null;
  cover_url: string | null;
}

interface CoverResult {
  source: string;
  url: string;
  sourceId?: string;
  confidence: number;
  matchMethod: string;
  width?: number;
  height?: number;
}

interface FetchResult {
  success: boolean;
  coverUrl?: string;
  source?: string;
  error?: string;
  cached?: boolean;
}

// ============================================
// ISBN NORMALIZATION
// ============================================

function normalizeIsbn(isbn: string | null): string | null {
  if (!isbn) return null;
  return isbn.replace(/[^0-9Xx]/g, "").toUpperCase();
}

function isbn10To13(isbn10: string): string | null {
  const normalized = normalizeIsbn(isbn10);
  if (!normalized || normalized.length !== 10) return null;

  const base = "978" + normalized.slice(0, 9);
  let sum = 0;
  for (let i = 0; i < 12; i++) {
    const digit = parseInt(base[i], 10);
    sum += i % 2 === 0 ? digit : digit * 3;
  }
  const checkDigit = (10 - (sum % 10)) % 10;
  return base + checkDigit.toString();
}

function isbn13To10(isbn13: string): string | null {
  const normalized = normalizeIsbn(isbn13);
  if (!normalized || normalized.length !== 13) return null;
  if (!normalized.startsWith("978")) return null;

  const base = normalized.slice(3, 12);
  let sum = 0;
  for (let i = 0; i < 9; i++) {
    sum += parseInt(base[i], 10) * (10 - i);
  }
  const remainder = (11 - (sum % 11)) % 11;
  const checkDigit = remainder === 10 ? "X" : remainder.toString();
  return base + checkDigit;
}

function getAllIsbnVariants(book: BookData): string[] {
  const variants: Set<string> = new Set();

  const addVariants = (isbn: string | null) => {
    if (!isbn) return;
    const normalized = normalizeIsbn(isbn);
    if (!normalized) return;

    variants.add(normalized);

    if (normalized.length === 10) {
      const isbn13 = isbn10To13(normalized);
      if (isbn13) variants.add(isbn13);
    } else if (normalized.length === 13) {
      const isbn10 = isbn13To10(normalized);
      if (isbn10) variants.add(isbn10);
    }
  };

  addVariants(book.isbn);
  addVariants(book.isbn10);
  addVariants(book.isbn13);

  return Array.from(variants);
}

// ============================================
// RATE LIMITING
// ============================================

async function checkRateLimit(
  supabase: any,
  apiName: string
): Promise<boolean> {
  const { data, error } = await supabase
    .from("api_rate_limits")
    .select("*")
    .eq("api_name", apiName)
    .single();

  if (error || !data) return true; // Allow if no limit configured

  const now = new Date();

  // Check if in backoff period
  if (data.backoff_until && new Date(data.backoff_until) > now) {
    return false;
  }

  const windowStart = new Date(data.window_start);
  const windowEnd = new Date(
    windowStart.getTime() + data.window_duration_seconds * 1000
  );

  // Reset window if expired
  if (now > windowEnd) {
    await supabase
      .from("api_rate_limits")
      .update({
        requests_count: 1,
        window_start: now.toISOString(),
        last_request_at: now.toISOString(),
      })
      .eq("api_name", apiName);
    return true;
  }

  // Check if under limit
  if (data.requests_count >= data.max_requests) {
    return false;
  }

  // Increment counter
  await supabase
    .from("api_rate_limits")
    .update({
      requests_count: data.requests_count + 1,
      last_request_at: now.toISOString(),
    })
    .eq("api_name", apiName);

  return true;
}

async function setBackoff(
  supabase: any,
  apiName: string,
  seconds: number
): Promise<void> {
  const backoffUntil = new Date(Date.now() + seconds * 1000);
  await supabase
    .from("api_rate_limits")
    .update({ backoff_until: backoffUntil.toISOString() })
    .eq("api_name", apiName);
}

// ============================================
// COVER SOURCES
// ============================================

async function fetchFromGoogleBooks(
  book: BookData,
  supabase: any
): Promise<CoverResult | null> {
  if (!(await checkRateLimit(supabase, "google_books"))) {
    console.log("Google Books rate limited");
    return null;
  }

  const isbns = getAllIsbnVariants(book);

  // Try by ISBN first
  for (const isbn of isbns) {
    try {
      const url = `https://www.googleapis.com/books/v1/volumes?q=isbn:${isbn}`;
      const response = await fetch(url);

      if (response.status === 429) {
        await setBackoff(supabase, "google_books", 60);
        return null;
      }

      if (response.ok) {
        const data = await response.json();
        if (data.items && data.items.length > 0) {
          const volumeInfo = data.items[0].volumeInfo;
          const imageLinks = volumeInfo?.imageLinks;

          if (imageLinks) {
            // Prefer higher resolution
            const coverUrl = (
              imageLinks.extraLarge ||
              imageLinks.large ||
              imageLinks.medium ||
              imageLinks.thumbnail ||
              imageLinks.smallThumbnail
            )
              ?.replace("http://", "https://")
              ?.replace("&edge=curl", "")
              ?.replace(/zoom=\d/, "zoom=3");

            if (coverUrl) {
              return {
                source: "google_books",
                url: coverUrl,
                sourceId: data.items[0].id,
                confidence: 1.0,
                matchMethod: "isbn_exact",
              };
            }
          }
        }
      }
    } catch (e) {
      console.error("Google Books error:", e);
    }
  }

  // Try by title + author
  if (book.title) {
    try {
      let query = `intitle:${encodeURIComponent(book.title)}`;
      if (book.author) {
        query += `+inauthor:${encodeURIComponent(book.author)}`;
      }

      const url = `https://www.googleapis.com/books/v1/volumes?q=${query}&maxResults=5`;
      const response = await fetch(url);

      if (response.ok) {
        const data = await response.json();
        if (data.items && data.items.length > 0) {
          // Find best match
          for (const item of data.items) {
            const volumeInfo = item.volumeInfo;
            const imageLinks = volumeInfo?.imageLinks;

            if (imageLinks) {
              const coverUrl = (
                imageLinks.extraLarge ||
                imageLinks.large ||
                imageLinks.medium ||
                imageLinks.thumbnail
              )
                ?.replace("http://", "https://")
                ?.replace("&edge=curl", "")
                ?.replace(/zoom=\d/, "zoom=3");

              if (coverUrl) {
                // Calculate title similarity
                const titleMatch = volumeInfo.title
                  ?.toLowerCase()
                  .includes(book.title.toLowerCase());
                const confidence = titleMatch ? 0.85 : 0.7;

                return {
                  source: "google_books",
                  url: coverUrl,
                  sourceId: item.id,
                  confidence,
                  matchMethod: "title_author_fuzzy",
                };
              }
            }
          }
        }
      }
    } catch (e) {
      console.error("Google Books title search error:", e);
    }
  }

  return null;
}

async function fetchFromOpenLibrary(
  book: BookData,
  supabase: any
): Promise<CoverResult | null> {
  if (!(await checkRateLimit(supabase, "open_library"))) {
    console.log("Open Library rate limited");
    return null;
  }

  const isbns = getAllIsbnVariants(book);

  // Try covers API directly (fastest)
  for (const isbn of isbns) {
    const coverUrl = `https://covers.openlibrary.org/b/isbn/${isbn}-L.jpg`;

    try {
      // Check if cover exists (HEAD request)
      const response = await fetch(coverUrl, { method: "HEAD" });

      if (response.ok) {
        const contentLength = response.headers.get("content-length");
        // Open Library returns a 1x1 pixel for missing covers (~807 bytes)
        if (contentLength && parseInt(contentLength) > 1000) {
          return {
            source: "open_library",
            url: coverUrl,
            sourceId: isbn,
            confidence: 1.0,
            matchMethod: "isbn_exact",
          };
        }
      }
    } catch (e) {
      console.error("Open Library error:", e);
    }
  }

  // Try Books API for more info
  for (const isbn of isbns) {
    try {
      const url = `https://openlibrary.org/api/books?bibkeys=ISBN:${isbn}&format=json&jscmd=data`;
      const response = await fetch(url);

      if (response.ok) {
        const data = await response.json();
        const bookData = data[`ISBN:${isbn}`];

        if (bookData?.cover) {
          const coverUrl = bookData.cover.large || bookData.cover.medium;
          if (coverUrl) {
            return {
              source: "open_library",
              url: coverUrl.replace("http://", "https://"),
              sourceId: isbn,
              confidence: 1.0,
              matchMethod: "isbn_exact",
            };
          }
        }
      }
    } catch (e) {
      console.error("Open Library API error:", e);
    }
  }

  return null;
}

// ============================================
// IMAGE VALIDATION
// ============================================

async function validateImage(url: string): Promise<boolean> {
  try {
    const response = await fetch(url, { method: "HEAD" });

    if (!response.ok) return false;

    const contentType = response.headers.get("content-type");
    if (!contentType?.startsWith("image/")) return false;

    const contentLength = response.headers.get("content-length");
    if (contentLength) {
      const size = parseInt(contentLength);
      // Minimum 1KB, maximum 10MB
      if (size < 1000 || size > 10 * 1024 * 1024) return false;
    }

    return true;
  } catch {
    return false;
  }
}

// ============================================
// STORAGE
// ============================================

async function uploadToStorage(
  supabase: any,
  bookId: string,
  source: string,
  imageUrl: string
): Promise<string | null> {
  try {
    // Fetch the image
    const response = await fetch(imageUrl);
    if (!response.ok) return null;

    const contentType = response.headers.get("content-type") || "image/jpeg";
    const buffer = await response.arrayBuffer();

    // Determine file extension
    let ext = "jpg";
    if (contentType.includes("png")) ext = "png";
    if (contentType.includes("webp")) ext = "webp";

    const fileName = `${bookId}/${source}_${Date.now()}.${ext}`;

    // Upload to Supabase Storage
    const { data, error } = await supabase.storage
      .from("book-covers")
      .upload(fileName, buffer, {
        contentType,
        cacheControl: "public, max-age=31536000", // 1 year cache
        upsert: true,
      });

    if (error) {
      console.error("Storage upload error:", error);
      return null;
    }

    // Get public URL
    const {
      data: { publicUrl },
    } = supabase.storage.from("book-covers").getPublicUrl(fileName);

    return publicUrl;
  } catch (e) {
    console.error("Upload error:", e);
    return null;
  }
}

// ============================================
// MAIN HANDLER
// ============================================

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const startTime = Date.now();

  try {
    const { book_id, force_refresh = false } = await req.json();

    if (!book_id) {
      return new Response(
        JSON.stringify({ error: "book_id is required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Initialize Supabase
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Get book data
    const { data: book, error: bookError } = await supabase
      .from("books")
      .select("*")
      .eq("id", book_id)
      .single();

    if (bookError || !book) {
      return new Response(
        JSON.stringify({ error: "Book not found" }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Check for existing valid cover
    if (!force_refresh) {
      const { data: existingCover } = await supabase
        .from("book_covers")
        .select("*")
        .eq("book_id", book_id)
        .eq("status", "ok")
        .order("created_at", { ascending: false })
        .limit(1)
        .single();

      if (existingCover?.cdn_url) {
        return new Response(
          JSON.stringify({
            success: true,
            coverUrl: existingCover.cdn_url,
            source: existingCover.source,
            cached: true,
          }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    // Try sources in priority order
    const sources = [
      { name: "google_books", fn: fetchFromGoogleBooks },
      { name: "open_library", fn: fetchFromOpenLibrary },
    ];

    const sourcesTried: string[] = [];
    let coverResult: CoverResult | null = null;

    for (const source of sources) {
      sourcesTried.push(source.name);

      try {
        coverResult = await source.fn(book as BookData, supabase);

        if (coverResult) {
          // Validate the image
          const isValid = await validateImage(coverResult.url);
          if (isValid) {
            break;
          } else {
            console.log(`Invalid image from ${source.name}, trying next...`);
            coverResult = null;
          }
        }
      } catch (e) {
        console.error(`Error with ${source.name}:`, e);
      }
    }

    const duration = Date.now() - startTime;

    // Log the attempt
    await supabase.from("cover_fetch_logs").insert({
      book_id,
      isbn_searched: book.isbn,
      title_searched: book.title,
      author_searched: book.author,
      sources_tried: sourcesTried,
      source_found: coverResult?.source || null,
      cover_url_found: coverResult?.url || null,
      duration_ms: duration,
      error_code: coverResult ? null : "NO_COVER_FOUND",
      error_message: coverResult ? null : "No cover found from any source",
      triggered_by: force_refresh ? "user_retry" : "auto",
    });

    if (!coverResult) {
      // Update book status
      await supabase
        .from("books")
        .update({
          cover_status: "missing",
          last_cover_attempt_at: new Date().toISOString(),
          cover_attempts: (book.cover_attempts || 0) + 1,
        })
        .eq("id", book_id);

      // Insert missing cover record
      await supabase.from("book_covers").upsert(
        {
          book_id,
          source: "google_books", // Primary source
          status: "error",
          error_message: "No cover found",
          attempts: (book.cover_attempts || 0) + 1,
          fetched_at: new Date().toISOString(),
        },
        { onConflict: "book_id,source" }
      );

      return new Response(
        JSON.stringify({
          success: false,
          error: "No cover found",
          sourcesTried,
          duration,
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Upload to storage for CDN delivery
    const cdnUrl = await uploadToStorage(
      supabase,
      book_id,
      coverResult.source,
      coverResult.url
    );

    const finalUrl = cdnUrl || coverResult.url;

    // Save cover record
    await supabase.from("book_covers").upsert(
      {
        book_id,
        source: coverResult.source,
        source_id: coverResult.sourceId,
        source_url: coverResult.url,
        cdn_url: finalUrl,
        storage_path: cdnUrl ? `${book_id}/${coverResult.source}` : null,
        status: "ok",
        match_confidence: coverResult.confidence,
        match_method: coverResult.matchMethod,
        fetched_at: new Date().toISOString(),
      },
      { onConflict: "book_id,source" }
    );

    // Update book
    await supabase
      .from("books")
      .update({
        cover_url: finalUrl,
        cover_status: "ok",
        last_cover_attempt_at: new Date().toISOString(),
      })
      .eq("id", book_id);

    return new Response(
      JSON.stringify({
        success: true,
        coverUrl: finalUrl,
        source: coverResult.source,
        confidence: coverResult.confidence,
        matchMethod: coverResult.matchMethod,
        cached: false,
        duration,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error in fetch-book-cover:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
