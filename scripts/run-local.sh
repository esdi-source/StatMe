#!/bin/bash
# StatMe - Local Development Run Script
# Runs the Flutter app in demo mode by default

set -e

echo "🏃 StatMe - Starting Local Development"
echo "======================================="

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed."
    echo "See: https://docs.flutter.dev/get-started/install"
    exit 1
fi

# Check for .env file
if [ ! -f .env ]; then
    echo "⚠️  .env file not found, creating from example..."
    if [ -f .env.example ]; then
        cp .env.example .env
        echo "✅ Created .env from .env.example"
    else
        echo "DEMO_MODE=true" > .env
        echo "✅ Created .env with DEMO_MODE=true"
    fi
fi

# Parse command line arguments
PLATFORM=""
RELEASE_MODE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --macos)
            PLATFORM="-d macos"
            shift
            ;;
        --windows)
            PLATFORM="-d windows"
            shift
            ;;
        --linux)
            PLATFORM="-d linux"
            shift
            ;;
        --web)
            PLATFORM="-d chrome"
            shift
            ;;
        --release)
            RELEASE_MODE="--release"
            shift
            ;;
        --production)
            export DEMO_MODE=false
            echo "🔌 Running in PRODUCTION mode (Supabase connected)"
            shift
            ;;
        --demo)
            export DEMO_MODE=true
            echo "🎭 Running in DEMO mode (no external connections)"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: ./run-local.sh [--macos|--windows|--linux|--web] [--release] [--production|--demo]"
            exit 1
            ;;
    esac
done

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Show current mode
source .env 2>/dev/null || true
if [ "$DEMO_MODE" = "true" ] || [ -z "$DEMO_MODE" ]; then
    echo "🎭 Demo Mode: ENABLED (default)"
    echo "   → No Supabase connection required"
    echo "   → Using local mock data"
else
    echo "🔌 Production Mode: ENABLED"
    echo "   → Connected to Supabase"
fi

echo ""
echo "🚀 Starting Flutter app..."
echo ""

# Run Flutter
flutter run $PLATFORM $RELEASE_MODE

