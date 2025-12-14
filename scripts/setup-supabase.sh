#!/bin/bash
# StatMe - Setup Script for Supabase Backend
# This script sets up Supabase for production use

set -e

echo "🚀 StatMe Supabase Setup"
echo "========================"

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI is not installed."
    echo "Install it with: brew install supabase/tap/supabase"
    echo "Or see: https://supabase.com/docs/guides/cli"
    exit 1
fi

# Check for .env file
if [ ! -f .env ]; then
    echo "❌ .env file not found!"
    echo "Please copy .env.example to .env and fill in your Supabase credentials."
    exit 1
fi

# Source environment variables
source .env

# Validate required environment variables
if [ -z "$SUPABASE_URL" ] || [ "$SUPABASE_URL" = "your_supabase_project_url" ]; then
    echo "❌ SUPABASE_URL is not configured in .env"
    exit 1
fi

if [ -z "$SUPABASE_ANON_KEY" ] || [ "$SUPABASE_ANON_KEY" = "your_supabase_anon_key" ]; then
    echo "❌ SUPABASE_ANON_KEY is not configured in .env"
    exit 1
fi

echo "✅ Environment configured"

# Initialize Supabase if not already done
if [ ! -f supabase/.gitignore ]; then
    echo "📦 Initializing Supabase project..."
    supabase init
fi

# Link to remote project (extract project ref from URL)
PROJECT_REF=$(echo $SUPABASE_URL | sed -n 's/.*\/\/\([^.]*\).*/\1/p')
if [ -n "$PROJECT_REF" ]; then
    echo "🔗 Linking to Supabase project: $PROJECT_REF"
    supabase link --project-ref "$PROJECT_REF" || true
fi

# Run migrations
echo "📊 Running database migrations..."
supabase db push

# Deploy Edge Functions
echo "⚡ Deploying Edge Functions..."
supabase functions deploy identify-product --no-verify-jwt
supabase functions deploy generate-occurrences

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Make sure your Supabase project has Email Auth enabled"
echo "2. Set DEMO_MODE=false in your .env to use Supabase"
echo "3. Run the app with: flutter run"
echo ""
echo "For local development with demo mode:"
echo "  DEMO_MODE=true flutter run"
