// filepath: /Users/alanalo/Documents/kloa/robloxCodeGenerator.js
const vscode = require('vscode');

/**
 * VS Code Extension für Roblox Lua/Luau Code-Generierung
 */
function activate(context) {
    console.log('Roblox Code Generator Extension ist aktiv');

    // Command zum Generieren von Lua Code registrieren
    const generateLuaCodeCommand = vscode.commands.registerCommand('extension.generateLuaCode', generateLuaCode);
    context.subscriptions.push(generateLuaCodeCommand);
}

/**
 * Generiert Lua Code basierend auf Benutzereingaben
 */
async function generateLuaCode() {
    const luaTemplate = `-- Roblox Lua Code

local function main()
    print('Hello, Roblox!')
end

main()`;

    const fileName = await vscode.window.showInputBox({
        prompt: 'Dateiname für die Lua-Datei eingeben',
        placeholder: 'script.lua'
    });

    if (!fileName) return;

    const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
    if (!workspaceFolder) {
        vscode.window.showErrorMessage('Kein Workspace geöffnet');
        return;
    }

    const fileUri = vscode.Uri.joinPath(workspaceFolder.uri, fileName);
    const content = new TextEncoder().encode(luaTemplate);
    await vscode.workspace.fs.writeFile(fileUri, content);
    vscode.window.showInformationMessage(`Lua-Datei erstellt: ${fileName}`);

    // Datei öffnen
    const document = await vscode.workspace.openTextDocument(fileUri);
    await vscode.window.showTextDocument(document);
}

function deactivate() {
    console.log('Roblox Code Generator Extension wurde deaktiviert');
}

module.exports = {
    activate,
    deactivate
};æ
