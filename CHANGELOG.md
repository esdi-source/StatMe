# Changelog

All notable changes to StatMe will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-15

### Added

#### Core Features
- **Demo Mode** - App runs fully offline with realistic mock data by default
- **Production Mode** - Full Supabase integration for cloud storage

#### Tracking Features
- **Todo Management**
  - Create, edit, delete todos
  - Priority levels (Low, Medium, High)
  - Recurring tasks with RRULE support (daily, weekly, monthly, yearly)
  - Track completion by occurrence date
  
- **Calorie/Food Tracking**
  - Log meals with nutritional information
  - Barcode scanning via OpenFoodFacts API (production mode)
  - Meal type categorization (breakfast, lunch, dinner, snack)
  - Daily calorie summary with goal tracking
  
- **Water Intake**
  - Quick-add buttons (250ml, 500ml, custom)
  - Daily goal progress visualization
  - Historical logging
  
- **Step Counter**
  - Manual step entry
  - Automatic distance calculation
  - Daily goal tracking
  
- **Sleep Tracking**
  - Bedtime and wake time logging
  - Automatic duration calculation
  - Sleep quality rating (1-5)
  - Notes support
  
- **Mood Journal**
  - Mood score (1-10 scale)
  - Energy level tracking
  - Stress level tracking
  - Custom notes

#### Statistics & Visualization
- **Dashboard** - Overview of all tracking metrics
- **Statistics Screen** - Interactive charts using fl_chart
  - Weekly calorie trends
  - Sleep duration patterns
  - Step count history
  - Mood trends

#### Settings
- Theme selection (Light/Dark/System)
- Customizable daily goals
- Notification preferences (placeholder)

### Technical
- Flutter 3.16+ desktop-first architecture
- Riverpod for state management
- Repository pattern for data layer abstraction
- InMemoryDatabase for demo mode
- Supabase integration for production:
  - PostgreSQL database with RLS policies
  - Edge Functions for barcode lookup
  - User authentication

### Database Schema
- `profiles` - User profile data
- `todos` - Todo items with RRULE support
- `todo_occurrences` - Individual occurrences of recurring todos
- `products_cache` - Cached product nutritional data
- `food_logs` - Food/calorie entries
- `water_logs` - Water intake records
- `steps_logs` - Daily step counts
- `sleep_logs` - Sleep session records
- `mood_logs` - Mood journal entries
- `settings` - User preferences and goals

### Security
- Row Level Security (RLS) on all user tables
- `auth.uid() = user_id` policy enforcement
- Service role for product cache updates

## [Unreleased]

### Planned
- Apple Health / Google Fit integration
- Widget support for quick logging
- Data export (CSV/JSON)
- Multiple user profiles
- Social features (optional sharing)
- Push notifications for reminders
- Offline-first with sync (SQLite + Supabase)
