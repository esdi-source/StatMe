#!/bin/bash
# StatMe Demo Starter
# Doppelklick auf diese Datei um die App zu starten

cd "$(dirname "$0")"

echo "🚀 StatMe Demo wird gestartet..."
echo "================================"
echo ""

# Prüfe ob Flutter installiert ist
if ! command -v flutter &> /dev/null; then
    # Versuche Flutter über fvm zu finden
    if [ -d "$HOME/fvm/default/bin" ]; then
        export PATH="$HOME/fvm/default/bin:$PATH"
    elif [ -d "$HOME/.pub-cache/bin" ]; then
        export PATH="$HOME/.pub-cache/bin:$PATH"
    elif [ -d "/opt/homebrew/bin" ]; then
        export PATH="/opt/homebrew/bin:$PATH"
    elif [ -d "/usr/local/bin" ]; then
        export PATH="/usr/local/bin:$PATH"
    fi
    
    # Lade Shell-Profil für Flutter-Pfad
    [ -f "$HOME/.zshrc" ] && source "$HOME/.zshrc" 2>/dev/null
    [ -f "$HOME/.bash_profile" ] && source "$HOME/.bash_profile" 2>/dev/null
fi

# Nochmal prüfen
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter wurde nicht gefunden!"
    echo ""
    echo "Bitte installiere Flutter: https://docs.flutter.dev/get-started/install"
    echo ""
    echo "Drücke eine Taste zum Beenden..."
    read -n 1
    exit 1
fi

echo "✅ Flutter gefunden: $(which flutter)"
echo ""

# .env Datei erstellen falls nicht vorhanden
if [ ! -f .env ]; then
    echo "📝 Erstelle .env Datei für Demo-Modus..."
    echo "DEMO_MODE=true" > .env
    echo "SUPABASE_URL=https://demo.supabase.co" >> .env
    echo "SUPABASE_ANON_KEY=demo-key" >> .env
fi

# Dependencies holen
echo "📦 Lade Abhängigkeiten..."
flutter pub get

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Fehler beim Laden der Abhängigkeiten!"
    echo "Drücke eine Taste zum Beenden..."
    read -n 1
    exit 1
fi

echo ""
echo "🎭 Starte StatMe im Demo-Modus..."
echo "   (Alle Daten sind lokal, keine Internet-Verbindung nötig)"
echo ""

# App starten
flutter run -d macos

echo ""
echo "App beendet. Drücke eine Taste zum Schließen..."
read -n 1
