#!/bin/bash
# Rojo Development Server Startup Script für Subway Surfers
# filepath: scripts/start-rojo.sh

echo "🎮 Starting Subway Surfers Rojo Development Server..."

# Prüfe ob Rojo installiert ist
if ! command -v rojo &> /dev/null; then
    echo "❌ Rojo nicht gefunden!"
    echo "💡 Installation: cargo install rojo"
    echo "📖 Mehr Info: https://rojo.space/docs/installation/"
    exit 1
fi

# Prüfe Rojo Version
ROJO_VERSION=$(rojo --version 2>/dev/null | head -n1)
echo "✅ Rojo Version: $ROJO_VERSION"

# Zeige Projekt-Info
echo "📁 Projektverzeichnis: $(pwd)"
echo "🔧 Konfiguration: default.project.json"

# Prüfe ob default.project.json existiert
if [ ! -f "default.project.json" ]; then
    echo "❌ default.project.json nicht gefunden!"
    echo "💡 Stelle sicher, dass du im richtigen Verzeichnis bist"
    exit 1
fi

# Starte Rojo Server mit optimierten Einstellungen
echo "🚀 Starting Rojo Server..."
echo "🔗 Server URL: http://localhost:34872"
echo "📱 Öffne Roblox Studio und verbinde mit dem Rojo Plugin"
echo "🛑 Zum Stoppen: Ctrl+C"
echo ""

# Starte mit erweiterten Optionen
rojo serve --port 34872 --verbose

echo "🔚 Rojo Server gestoppt"
