# StatMe - Health & Productivity Tracker

A Flutter desktop-first application for tracking todos, calories, water intake, steps, sleep, and mood with comprehensive statistics.

## Features

- 📝 **Todo Management** - Create, edit, and track todos with recurring task support (RRULE)
- 🍎 **Calorie Tracking** - Log food with barcode scanning and nutritional information
- 💧 **Water Intake** - Track daily hydration with customizable goals
- 👟 **Step Counter** - Manual step logging with distance calculation
- 😴 **Sleep Tracking** - Log bedtime, wake time, and sleep quality
- 🎭 **Mood Journal** - Track mood, energy, and stress levels
- 📊 **Statistics** - Visualize your health data with interactive charts

## Demo Mode

By default, the app runs in **Demo Mode** which requires no external services:

- ✅ No Supabase connection needed
- ✅ No internet required
- ✅ Pre-populated with realistic sample data
- ✅ All features fully functional

## Quick Start

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.16.0+)
- For desktop: Platform-specific requirements
  - **macOS**: Xcode
  - **Windows**: Visual Studio with C++ workload
  - **Linux**: Required packages (see Flutter docs)

### Run in Demo Mode (Default)

```bash
# Clone the repository
cd StatMe

# Create environment file
cp .env.example .env

# Get dependencies
flutter pub get

# Run on your platform
flutter run -d macos    # macOS
flutter run -d windows  # Windows
flutter run -d linux    # Linux
flutter run -d chrome   # Web
```

Or use the convenience script:

```bash
chmod +x scripts/run-local.sh
./scripts/run-local.sh --macos
```

### Run in Production Mode

1. **Set up Supabase project** at [supabase.com](https://supabase.com)

2. **Configure environment variables** in `.env`:
   ```env
   DEMO_MODE=false
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```

3. **Run migrations**:
   ```bash
   chmod +x scripts/setup-supabase.sh
   ./scripts/setup-supabase.sh
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                 # Entry point
├── src/
│   ├── core/
│   │   └── config/
│   │       └── app_config.dart    # Demo mode configuration
│   ├── models/               # Data models
│   │   ├── todo_model.dart
│   │   ├── food_model.dart
│   │   ├── water_model.dart
│   │   └── ...
│   ├── providers/            # Riverpod providers
│   │   └── providers.dart
│   ├── repositories/         # Data access layer
│   │   ├── repository_interfaces.dart
│   │   ├── demo_repositories.dart
│   │   └── supabase_repositories.dart
│   ├── services/             # Business logic
│   │   ├── demo_data_service.dart
│   │   └── in_memory_database.dart
│   ├── screens/              # UI screens
│   │   ├── dashboard_screen.dart
│   │   ├── todos_screen.dart
│   │   └── ...
│   └── ui/
│       ├── app.dart
│       └── theme/
│           └── app_theme.dart
supabase/
├── migrations/               # Database schema
│   ├── 20240101000000_initial_schema.sql
│   └── 20240101000001_rls_policies.sql
└── functions/                # Edge Functions
    ├── identify-product/
    └── generate-occurrences/
```

## Architecture

### Demo Mode Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   UI Screens    │────▶│ Riverpod Providers│────▶│  Repositories   │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                                                          │
                               ┌──────────────────────────┼──────────────────────────┐
                               │                          │                          │
                               ▼                          ▼                          ▼
                     ┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
                     │ Demo Repository │       │Supabase Repository│      │  (Future: SQLite)│
                     └─────────────────┘       └─────────────────┘       └─────────────────┘
                               │                          │
                               ▼                          ▼
                     ┌─────────────────┐       ┌─────────────────┐
                     │ InMemoryDatabase│       │  Supabase Cloud │
                     └─────────────────┘       └─────────────────┘
```

### Key Components

- **AppConfig**: Singleton that reads `DEMO_MODE` from environment
- **Repository Interfaces**: Abstract classes defining data operations
- **Demo Repositories**: Use InMemoryDatabase with DemoDataService for sample data
- **Supabase Repositories**: Connect to Supabase for production use
- **Providers**: Conditionally inject correct repositories based on mode

## Customization

### Adding New Tracking Features

1. Create model in `lib/src/models/`
2. Add repository interface in `repository_interfaces.dart`
3. Implement demo repository in `demo_repositories.dart`
4. Implement Supabase repository in `supabase_repositories.dart`
5. Add provider in `providers.dart`
6. Create UI screen in `lib/src/screens/`

### Changing Goals

Default goals can be modified in:
- `lib/src/models/settings_model.dart` - Default values
- Settings screen in the app - Per-user customization

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## Building for Production

### macOS
```bash
flutter build macos --release
```

### Windows
```bash
flutter build windows --release
```

### Web
```bash
flutter build web --release
```

## License

MIT License - see LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.
