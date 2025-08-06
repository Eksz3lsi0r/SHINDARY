#!/bin/bash
# VS Code Copilot Configuration Verification and Optimization Script
# Für optimale Roblox Lua/Luau Entwicklung mit GitHub Copilot

echo "🚀 VS Code Copilot Optimierung für Roblox Development"
echo "=================================================="

# Funktion zur Überprüfung der VS Code Installation
check_vscode() {
    if command -v code &> /dev/null; then
        echo "✅ VS Code ist installiert: $(code --version | head -1)"
    else
        echo "❌ VS Code nicht gefunden. Bitte installieren Sie VS Code."
        exit 1
    fi
}

# Funktion zur Überprüfung der Extensions
check_extensions() {
    echo "🔍 Überprüfe VS Code Extensions..."

    required_extensions=(
        "GitHub.copilot"
        "GitHub.copilot-chat"
        "JohnnyMorganz.luau-lsp"
        "nightrains.robloxlsp"
        "JohnnyMorganz.stylua"
        "DavidAnson.vscode-markdownlint"
    )

    installed_extensions=$(code --list-extensions)

    for ext in "${required_extensions[@]}"; do
        if echo "$installed_extensions" | grep -q "$ext"; then
            echo "✅ $ext ist installiert"
        else
            echo "⚠️  $ext fehlt - wird installiert..."
            code --install-extension "$ext"
        fi
    done
}

# Funktion zur Überprüfung der Roblox Tools
check_roblox_tools() {
    echo "🎮 Überprüfe Roblox Development Tools..."

    if command -v rojo &> /dev/null; then
        echo "✅ Rojo ist installiert: $(rojo --version)"
    else
        echo "⚠️  Rojo nicht gefunden. Installation empfohlen:"
        echo "   brew install rojo"
    fi

    if command -v stylua &> /dev/null; then
        echo "✅ StyLua ist installiert: $(stylua --version)"
    else
        echo "⚠️  StyLua nicht gefunden. Installation empfohlen:"
        echo "   brew install stylua"
    fi
}

# Funktion zur Validierung der Copilot-Einstellungen
validate_copilot_settings() {
    echo "⚙️  Validiere Copilot Einstellungen..."

    settings_file="$HOME/Library/Application Support/Code/User/settings.json"

    if [[ -f "$settings_file" ]]; then
        echo "✅ Globale VS Code Einstellungen gefunden"

        # Überprüfe wichtige Copilot-Einstellungen
        if grep -q "github.copilot.chat.experimental.codebaseContext" "$settings_file"; then
            echo "✅ Experimentelle Codebase Context aktiviert"
        else
            echo "⚠️  Experimentelle Codebase Context nicht aktiviert"
        fi

        if grep -q "github.copilot.chat.useCodebase" "$settings_file"; then
            echo "✅ Codebase Usage aktiviert"
        else
            echo "⚠️  Codebase Usage nicht aktiviert"
        fi
    else
        echo "⚠️  Globale VS Code Einstellungen nicht gefunden"
    fi
}

# Funktion zur Überprüfung der Workspace-Einstellungen
validate_workspace_settings() {
    echo "📁 Validiere Workspace Einstellungen..."

    workspace_settings=".vscode/settings.json"

    if [[ -f "$workspace_settings" ]]; then
        echo "✅ Workspace Einstellungen gefunden"

        # Überprüfe Luau-spezifische Einstellungen
        if grep -q "luau-lsp.types.roblox" "$workspace_settings"; then
            echo "✅ Roblox Luau Types aktiviert"
        fi

        if grep -q "rojo." "$workspace_settings"; then
            echo "✅ Rojo Integration konfiguriert"
        fi
    else
        echo "⚠️  Workspace Einstellungen nicht gefunden"
    fi
}

# Funktion zum Testen der Copilot-Funktionalität
test_copilot_functionality() {
    echo "🧪 Teste Copilot Integration..."

    # Teste ob Copilot Chat verfügbar ist
    if code --list-extensions | grep -q "GitHub.copilot-chat"; then
        echo "✅ Copilot Chat Extension verfügbar"
    fi

    # Teste Workspace-Struktur für Roblox
    if [[ -f "default.project.json" ]]; then
        echo "✅ Rojo Projekt-Datei gefunden"
    fi

    if [[ -d "src" ]]; then
        echo "✅ Source-Verzeichnis gefunden"

        lua_files=$(find src -name "*.lua" -o -name "*.luau" | wc -l)
        echo "📊 $lua_files Lua/Luau Dateien im Projekt"
    fi
}

# Funktion zur Generierung eines Optimierungsberichts
generate_optimization_report() {
    echo "📊 Generiere Optimierungsbericht..."

    report_file="copilot-optimization-report.md"

    cat > "$report_file" << EOF
# GitHub Copilot Optimierungsbericht für Roblox Development

## ✅ Konfigurationsstatus

### VS Code Extensions
$(code --list-extensions | grep -E "(copilot|luau|roblox|stylua)" | sed 's/^/- /')

### Entwicklungstools
- Rojo: $(rojo --version 2>/dev/null || echo "Nicht installiert")
- StyLua: $(stylua --version 2>/dev/null || echo "Nicht installiert")

### Projekt-Struktur
- Rojo Projekt: $(test -f "default.project.json" && echo "✅ Gefunden" || echo "❌ Nicht gefunden")
- Source-Verzeichnis: $(test -d "src" && echo "✅ Gefunden" || echo "❌ Nicht gefunden")
- Lua/Luau Dateien: $(find src -name "*.lua" -o -name "*.luau" 2>/dev/null | wc -l || echo "0")

### Empfohlene nächste Schritte
1. Überprüfe Copilot Chat Funktionalität mit Cmd+Shift+C
2. Teste semantische Suche in der Codebase
3. Nutze Inline-Suggestions für Luau Code
4. Verwende Rojo Sync für Live-Updates in Roblox Studio

## 🎯 Optimierungstipps

### Für bessere Copilot-Suggestions:
- Verwende aussagekräftige Kommentare auf Deutsch
- Nutze Type-Annotations in Luau
- Strukturiere Code in logische Module
- Implementiere Error-Handling mit pcall()

### Für bessere Codebase-Erkennung:
- Halte Dateinamen konsistent (.server.lua, .client.lua, .module.lua)
- Nutze klare Ordnerstrukturen (client/, server/, shared/)
- Dokumentiere RemoteEvents und ihre Parameter
- Verwende aussagekräftige Variablen- und Funktionsnamen

Generiert am: $(date)
EOF

    echo "📄 Bericht gespeichert in: $report_file"
}

# Hauptausführung
main() {
    check_vscode
    check_extensions
    check_roblox_tools
    validate_copilot_settings
    validate_workspace_settings
    test_copilot_functionality
    generate_optimization_report

    echo ""
    echo "🎉 Copilot Optimierung abgeschlossen!"
    echo "💡 Nutze Cmd+Shift+C für Copilot Chat"
    echo "🔍 Nutze Cmd+Shift+S für erweiterte Suche"
    echo "🚀 Viel Erfolg bei der Roblox Entwicklung!"
}

# Script ausführen
main
