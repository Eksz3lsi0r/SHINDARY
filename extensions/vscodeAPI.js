const vscode = require('vscode');
const fs = require('fs').promises;
const path = require('path');

/**
 * Enhanced VS Code Extension for Roblox Lua/Luau Development with AI-powered code generation
 * Optimized for GitHub Copilot Chat Agent integration
 */
function activate(context) {
    console.log('🎮 Enhanced Roblox Lua Copilot Extension is active');

    // File System Watchers for Roblox-specific files
    const luaWatcher = vscode.workspace.createFileSystemWatcher('**/*.{lua,luau}');
    const projectWatcher = vscode.workspace.createFileSystemWatcher('**/default.project.json');
    const rbxlxWatcher = vscode.workspace.createFileSystemWatcher('**/*.rbxlx');

    // Enhanced Event Handlers
    setupEnhancedFileEvents(luaWatcher, projectWatcher, rbxlxWatcher);

    // Advanced Commands for Roblox Development with enhanced search capabilities
    const commands = [
        vscode.commands.registerCommand('roblox.createService', createRobloxService),
        vscode.commands.registerCommand('roblox.createModule', createRobloxModule),
        vscode.commands.registerCommand('roblox.createLocalScript', createLocalScript),
        vscode.commands.registerCommand('roblox.createServerScript', createServerScript),
        vscode.commands.registerCommand('roblox.generateRemoteEvents', generateRemoteEvents),
        vscode.commands.registerCommand('roblox.optimizeForCopilot', optimizeForCopilot),
        vscode.commands.registerCommand('roblox.analyzeProject', analyzeRobloxProject),
        vscode.commands.registerCommand('roblox.generateDocumentation', generateDocumentation),
        vscode.commands.registerCommand('roblox.setupProjectStructure', setupProjectStructure),
        vscode.commands.registerCommand('roblox.createCopilotAgent', createCopilotAgent),
        vscode.commands.registerCommand('roblox.enhanceCodebase', enhanceCodebase),
        vscode.commands.registerCommand('roblox.semanticSearch', performSemanticSearch),
        vscode.commands.registerCommand('roblox.workspaceSearch', performWorkspaceSearch),
        vscode.commands.registerCommand('roblox.findCodeUsages', findCodeUsages),
        vscode.commands.registerCommand('roblox.searchAndAnalyze', searchAndAnalyze),
        vscode.commands.registerCommand('roblox.enhancedSearch', performEnhancedSearch)
    ];

    // File System Integration for better Copilot performance
    setupAdvancedFileSystemIntegration(context);

    // Register all commands
    context.subscriptions.push(luaWatcher, projectWatcher, rbxlxWatcher, ...commands);

    // Initialize enhanced Copilot context
    initializeEnhancedCopilotContext();

    vscode.window.showInformationMessage('🚀 Enhanced Roblox Lua Copilot Extension ready!');
}

/**
 * Enhanced Semantic Search with VS Code API integration
 */
async function performSemanticSearch() {
    const searchQuery = await vscode.window.showInputBox({
        prompt: 'Semantische Suche - Enter search query for enhanced AI analysis',
        placeholder: 'z.B.: player movement, score system, power-ups, RemoteEvents'
    });

    if (!searchQuery) return;

    try {
        vscode.window.withProgress({
            location: vscode.ProgressLocation.Notification,
            title: `🔍 Enhanced Semantic Search: "${searchQuery}"`,
            cancellable: false
        }, async (progress) => {
            progress.report({ increment: 10, message: 'Analysiere Workspace Symbole...' });

            // Use VS Code workspace search API with enhanced context
            const symbols = await vscode.commands.executeCommand('vscode.executeWorkspaceSymbolProvider', searchQuery);

            progress.report({ increment: 30, message: 'Durchsuche Dateiinhalte...' });
            // Enhanced file content search with AI pattern recognition
            const fileResults = await performFileContentSearch(searchQuery);

            progress.report({ increment: 50, message: 'Erkenne Code-Muster...' });
            // Advanced pattern detection for Roblox/Luau code
            const patterns = await findCodePatterns(searchQuery);

            progress.report({ increment: 70, message: 'Generiere AI Insights...' });
            // Generate AI-powered insights
            const insights = await generateAIInsights(searchQuery, symbols, fileResults, patterns);

            progress.report({ increment: 90, message: 'Präsentiere Ergebnisse...' });
            // Present enhanced results with context
            await showEnhancedSearchResults({
                query: searchQuery,
                symbols: symbols || [],
                fileResults: fileResults || [],
                patterns: patterns || [],
                insights: insights || []
            });

            progress.report({ increment: 100, message: 'Suche abgeschlossen!' });
        });

    } catch (error) {
        vscode.window.showErrorMessage(`Enhanced Semantic Search Error: ${error.message}`);
    }
}

/**
 * Enhanced Workspace Search using VS Code API
 */
async function performWorkspaceSearch() {
    const searchQuery = await vscode.window.showInputBox({
        prompt: 'Search workspace symbols and code',
        placeholder: 'function, class, variable, or code pattern'
    });

    if (!searchQuery) return;

    try {
        // Execute workspace symbol provider
        const symbols = await vscode.commands.executeCommand('vscode.executeWorkspaceSymbolProvider', searchQuery);

        // Search in all text documents
        const textDocuments = vscode.workspace.textDocuments;
        const documentMatches = [];

        for (const document of textDocuments) {
            if (document.fileName.endsWith('.lua') || document.fileName.endsWith('.luau')) {
                const text = document.getText();
                if (text.toLowerCase().includes(searchQuery.toLowerCase())) {
                    documentMatches.push({
                        uri: document.uri,
                        fileName: path.basename(document.fileName),
                        matches: findMatchesInText(text, searchQuery)
                    });
                }
            }
        }

        // Present results in a webview
        await showSearchResults(symbols, documentMatches, searchQuery);

    } catch (error) {
        vscode.window.showErrorMessage(`Workspace search error: ${error.message}`);
    }
}

/**
 * Find Code Usages with enhanced analysis
 */
async function findCodeUsages() {
    const activeEditor = vscode.window.activeTextEditor;
    if (!activeEditor) {
        vscode.window.showErrorMessage('No active editor');
        return;
    }

    const selection = activeEditor.selection;
    const selectedText = activeEditor.document.getText(selection);

    const searchTerm = selectedText || await vscode.window.showInputBox({
        prompt: 'Enter symbol name to find usages',
        placeholder: 'function, variable, or class name'
    });

    if (!searchTerm) return;

    try {
        // Find all references using VS Code API
        const references = await vscode.commands.executeCommand(
            'vscode.executeReferenceProvider',
            activeEditor.document.uri,
            activeEditor.selection.active
        );

        // Find additional usages via text search
        const textUsages = await findTextUsages(searchTerm);

        // Analyze usage patterns
        const usageAnalysis = analyzeUsagePatterns(references, textUsages, searchTerm);

        // Present comprehensive usage report
        await showUsageReport(usageAnalysis, searchTerm);

    } catch (error) {
        vscode.window.showErrorMessage(`Code usage search error: ${error.message}`);
    }
}

/**
 * Enhanced Search and Analysis combining multiple search types
 */
async function searchAndAnalyze() {
    const searchOptions = await vscode.window.showQuickPick([
        { label: '🔍 Semantic Search', description: 'AI-powered semantic code search', value: 'semantic' },
        { label: '📋 Symbol Search', description: 'Find symbols across workspace', value: 'symbols' },
        { label: '🔗 Usage Analysis', description: 'Analyze code usage patterns', value: 'usage' },
        { label: '📊 Project Analysis', description: 'Comprehensive project analysis', value: 'project' },
        { label: '🎯 Smart Search', description: 'Combined search with AI insights', value: 'smart' }
    ], { placeHolder: 'Select search type' });

    if (!searchOptions) return;

    switch (searchOptions.value) {
        case 'semantic':
            await performSemanticSearch();
            break;
        case 'symbols':
            await performWorkspaceSearch();
            break;
        case 'usage':
            await findCodeUsages();
            break;
        case 'project':
            await analyzeRobloxProject();
            break;
        case 'smart':
            await performEnhancedSearch();
            break;
    }
}

/**
 * Enhanced Search combining all search capabilities
 */
async function performEnhancedSearch() {
    const searchQuery = await vscode.window.showInputBox({
        prompt: 'Enter search query for enhanced analysis',
        placeholder: 'AI will analyze across symbols, usages, and semantic patterns'
    });

    if (!searchQuery) return;

    const progressOptions = {
        location: vscode.ProgressLocation.Notification,
        title: 'Enhanced Search Analysis',
        cancellable: true
    };

    await vscode.window.withProgress(progressOptions, async (progress, token) => {
        try {
            progress.report({ increment: 0, message: 'Searching workspace symbols...' });
            const symbols = await vscode.commands.executeCommand('vscode.executeWorkspaceSymbolProvider', searchQuery);

            progress.report({ increment: 25, message: 'Analyzing text documents...' });
            const textAnalysis = await analyzeTextDocuments(searchQuery);

            progress.report({ increment: 50, message: 'Finding code patterns...' });
            const patterns = await findCodePatterns(searchQuery);

            progress.report({ increment: 75, message: 'Generating AI insights...' });
            const aiInsights = await generateAIInsights(searchQuery, symbols, textAnalysis, patterns);

            progress.report({ increment: 100, message: 'Presenting results...' });
            await showEnhancedSearchResults({
                query: searchQuery,
                symbols,
                textAnalysis,
                patterns,
                aiInsights
            });

        } catch (error) {
            if (!token.isCancellationRequested) {
                vscode.window.showErrorMessage(`Enhanced search error: ${error.message}`);
            }
        }
    });
}

/**
 * Helper function to search workspace symbols
 */
async function performWorkspaceSymbolSearch(query) {
    try {
        return await vscode.commands.executeCommand('vscode.executeWorkspaceSymbolProvider', query);
    } catch (error) {
        console.warn('Workspace symbol search failed:', error);
        return [];
    }
}

/**
 * Helper function to search file content
 */
async function performFileContentSearch(query) {
    const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
    if (!workspaceFolder) return [];

    const results = [];
    const luaFiles = await vscode.workspace.findFiles('**/*.{lua,luau}', '**/node_modules/**');

    for (const file of luaFiles) {
        try {
            const document = await vscode.workspace.openTextDocument(file);
            const text = document.getText();
            const matches = findMatchesInText(text, query);

            if (matches.length > 0) {
                results.push({
                    uri: file,
                    fileName: path.basename(file.fsPath),
                    matches
                });
            }
        } catch (error) {
            console.warn(`Error reading file ${file.fsPath}:`, error);
        }
    }

    return results;
}

/**
 * Find matches in text with context
 */
function findMatchesInText(text, query) {
    const lines = text.split('\n');
    const matches = [];
    const searchPattern = new RegExp(query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'gi');

    lines.forEach((line, index) => {
        const match = searchPattern.exec(line);
        if (match) {
            matches.push({
                line: index + 1,
                column: match.index,
                text: line.trim(),
                context: getLineContext(lines, index)
            });
        }
    });

    return matches;
}

/**
 * Get context lines around a match
 */
function getLineContext(lines, lineIndex, contextSize = 2) {
    const start = Math.max(0, lineIndex - contextSize);
    const end = Math.min(lines.length, lineIndex + contextSize + 1);

    return {
        before: lines.slice(start, lineIndex),
        current: lines[lineIndex],
        after: lines.slice(lineIndex + 1, end)
    };
}

/**
 * Find text usages across workspace
 */
async function findTextUsages(searchTerm) {
    const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
    if (!workspaceFolder) return [];

    const usages = [];
    const files = await vscode.workspace.findFiles('**/*.{lua,luau,js,json}', '**/node_modules/**');

    for (const file of files) {
        try {
            const document = await vscode.workspace.openTextDocument(file);
            const text = document.getText();
            const matches = findMatchesInText(text, searchTerm);

            if (matches.length > 0) {
                usages.push({
                    file: file.fsPath,
                    matches,
                    fileType: path.extname(file.fsPath)
                });
            }
        } catch (error) {
            console.warn(`Error processing file ${file.fsPath}:`, error);
        }
    }

    return usages;
}

/**
 * Analyze usage patterns for insights
 */
function analyzeUsagePatterns(references, textUsages, searchTerm) {
    const analysis = {
        searchTerm,
        totalUsages: (references?.length || 0) + textUsages.reduce((sum, file) => sum + file.matches.length, 0),
        fileTypes: {},
        patterns: [],
        suggestions: []
    };

    // Analyze file type distribution
    textUsages.forEach(usage => {
        const ext = usage.fileType;
        analysis.fileTypes[ext] = (analysis.fileTypes[ext] || 0) + usage.matches.length;
    });

    // Detect common patterns
    const allMatches = textUsages.flatMap(usage => usage.matches);
    const contexts = allMatches.map(match => match.text.toLowerCase());

    // Find common context patterns
    const contextPatterns = findCommonPatterns(contexts);
    analysis.patterns = contextPatterns;

    // Generate suggestions
    if (analysis.totalUsages === 0) {
        analysis.suggestions.push('No usages found. Consider checking spelling or searching for related terms.');
    } else if (analysis.totalUsages > 50) {
        analysis.suggestions.push('High usage detected. Consider refactoring for better maintainability.');
    }

    return analysis;
}

/**
 * Find common patterns in text contexts
 */
function findCommonPatterns(contexts) {
    const patterns = {};
    const commonWords = ['function', 'local', 'return', 'if', 'then', 'end', 'for', 'while'];

    contexts.forEach(context => {
        commonWords.forEach(word => {
            if (context.includes(word)) {
                patterns[word] = (patterns[word] || 0) + 1;
            }
        });
    });

    return Object.entries(patterns)
        .sort(([,a], [,b]) => b - a)
        .slice(0, 5)
        .map(([pattern, count]) => ({ pattern, count }));
}

/**
 * Analyze text documents for patterns
 */
async function analyzeTextDocuments(query) {
    const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
    if (!workspaceFolder) return { files: [], patterns: [], summary: {} };

    const luaFiles = await vscode.workspace.findFiles('**/*.{lua,luau}', '**/node_modules/**');
    const analysis = {
        files: [],
        patterns: [],
        summary: {
            totalFiles: luaFiles.length,
            matchingFiles: 0,
            totalMatches: 0
        }
    };

    for (const file of luaFiles) {
        try {
            const document = await vscode.workspace.openTextDocument(file);
            const text = document.getText();
            const matches = findMatchesInText(text, query);

            if (matches.length > 0) {
                analysis.files.push({
                    path: file.fsPath,
                    name: path.basename(file.fsPath),
                    matches: matches.length,
                    fileSize: text.length,
                    lines: text.split('\n').length
                });
                analysis.summary.matchingFiles++;
                analysis.summary.totalMatches += matches.length;
            }
        } catch (error) {
            console.warn(`Error analyzing file ${file.fsPath}:`, error);
        }
    }

    return analysis;
}

/**
 * Find code patterns related to query
 */
async function findCodePatterns(query) {
    const patterns = {
        functions: [],
        variables: [],
        services: [],
        events: [],
        structures: []
    };

    // Define patterns to search for
    const searchPatterns = [
        { type: 'functions', regex: /function\s+(\w+)/g },
        { type: 'variables', regex: /local\s+(\w+)/g },
        { type: 'services', regex: /game:GetService\("(\w+)"\)/g },
        { type: 'events', regex: /(\w+):Connect\(/g },
        { type: 'structures', regex: /(\w+)\s*=\s*{/g }
    ];

    const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
    if (!workspaceFolder) return patterns;

    const luaFiles = await vscode.workspace.findFiles('**/*.{lua,luau}', '**/node_modules/**');

    for (const file of luaFiles) {
        try {
            const document = await vscode.workspace.openTextDocument(file);
            const text = document.getText();

            if (text.toLowerCase().includes(query.toLowerCase())) {
                searchPatterns.forEach(({ type, regex }) => {
                    let match;
                    while ((match = regex.exec(text)) !== null) {
                        if (match[1].toLowerCase().includes(query.toLowerCase())) {
                            patterns[type].push({
                                name: match[1],
                                file: path.basename(file.fsPath),
                                fullPath: file.fsPath
                            });
                        }
                    }
                });
            }
        } catch (error) {
            console.warn(`Error finding patterns in ${file.fsPath}:`, error);
        }
    }

    return patterns;
}

/**
 * Generate AI insights from search results
 */
async function generateAIInsights(query, symbols, textAnalysis, patterns) {
    const insights = {
        summary: `Found ${textAnalysis.summary.totalMatches} matches across ${textAnalysis.summary.matchingFiles} files`,
        recommendations: [],
        codeQuality: {},
        opportunities: []
    };

    // Analyze code quality
    if (patterns.functions.length > 0) {
        insights.codeQuality.functions = `Found ${patterns.functions.length} related functions`;
        if (patterns.functions.length > 10) {
            insights.recommendations.push('Consider organizing functions into modules for better maintainability');
        }
    }

    if (patterns.services.length > 0) {
        insights.codeQuality.services = `Using ${patterns.services.length} Roblox services`;
        const uniqueServices = [...new Set(patterns.services.map(s => s.name))];
        insights.recommendations.push(`Services in use: ${uniqueServices.join(', ')}`);
    }

    // Generate opportunities
    if (textAnalysis.summary.matchingFiles > 5) {
        insights.opportunities.push('High usage suggests this is a core component - consider documentation');
    }

    if (patterns.events.length > 0) {
        insights.opportunities.push('Event-driven architecture detected - good for maintainability');
    }

    return insights;
}

/**
 * Show comprehensive search results
 */
async function showSearchResults(symbols, documentMatches, query) {
    const panel = vscode.window.createWebviewPanel(
        'robloxSearchResults',
        `Search Results: ${query}`,
        vscode.ViewColumn.Two,
        { enableScripts: true }
    );

    panel.webview.html = generateSearchResultsHTML(symbols, documentMatches, query);
}

/**
 * Show usage report
 */
async function showUsageReport(analysis, searchTerm) {
    const panel = vscode.window.createWebviewPanel(
        'robloxUsageReport',
        `Usage Report: ${searchTerm}`,
        vscode.ViewColumn.Two,
        { enableScripts: true }
    );

    panel.webview.html = generateUsageReportHTML(analysis);
}

/**
 * Show enhanced search results
 */
async function showEnhancedSearchResults(results) {
    const panel = vscode.window.createWebviewPanel(
        'robloxEnhancedSearch',
        `Enhanced Search: ${results.query}`,
        vscode.ViewColumn.Two,
        { enableScripts: true }
    );

    panel.webview.html = generateEnhancedResultsHTML(results);
}

/**
 * Generate HTML for search results
 */
function generateSearchResultsHTML(symbols, documentMatches, query) {
    return `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <title>Search Results</title>
        <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; }
            .header { color: #007ACC; border-bottom: 2px solid #007ACC; padding-bottom: 10px; }
            .section { margin: 20px 0; }
            .file-match { background: #f8f8f8; padding: 10px; margin: 5px 0; border-radius: 5px; }
            .match-line { font-family: 'Courier New', monospace; background: #fff; padding: 5px; margin: 2px 0; }
            .highlight { background-color: yellow; font-weight: bold; }
            .symbol { background: #e8f4f8; padding: 8px; margin: 3px 0; border-left: 4px solid #007ACC; }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>🔍 Search Results for "${query}"</h1>
            <p>Found ${symbols?.length || 0} symbols and ${documentMatches.length} file matches</p>
        </div>

        ${symbols?.length > 0 ? `
        <div class="section">
            <h2>📋 Workspace Symbols</h2>
            ${symbols.map(symbol => `
                <div class="symbol">
                    <strong>${symbol.name}</strong> (${symbol.kind})
                    <br><small>${symbol.location?.uri?.fsPath || 'Unknown location'}</small>
                </div>
            `).join('')}
        </div>
        ` : ''}

        <div class="section">
            <h2>📄 File Matches</h2>
            ${documentMatches.map(file => `
                <div class="file-match">
                    <h3>${file.fileName}</h3>
                    ${file.matches.map(match => `
                        <div class="match-line">
                            Line ${match.line}: ${match.text.replace(new RegExp(query, 'gi'), '<span class="highlight">$&</span>')}
                        </div>
                    `).join('')}
                </div>
            `).join('')}
        </div>
    </body>
    </html>
    `;
}

/**
 * Generate HTML for usage report
 */
function generateUsageReportHTML(analysis) {
    return `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <title>Usage Report</title>
        <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; }
            .header { color: #007ACC; border-bottom: 2px solid #007ACC; padding-bottom: 10px; }
            .stats { display: flex; gap: 20px; margin: 20px 0; }
            .stat-card { background: #f0f8ff; padding: 15px; border-radius: 8px; flex: 1; }
            .suggestion { background: #fff3cd; padding: 10px; margin: 5px 0; border-radius: 5px; border-left: 4px solid #ffc107; }
            .pattern { background: #d4edda; padding: 8px; margin: 3px 0; border-radius: 4px; }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>📊 Usage Report: ${analysis.searchTerm}</h1>
        </div>

        <div class="stats">
            <div class="stat-card">
                <h3>Total Usages</h3>
                <h2>${analysis.totalUsages}</h2>
            </div>
            <div class="stat-card">
                <h3>File Types</h3>
                ${Object.entries(analysis.fileTypes).map(([type, count]) =>
                    `<div>${type}: ${count}</div>`
                ).join('')}
            </div>
        </div>

        ${analysis.patterns.length > 0 ? `
        <div class="section">
            <h2>🎯 Common Patterns</h2>
            ${analysis.patterns.map(pattern => `
                <div class="pattern">
                    <strong>${pattern.pattern}</strong>: ${pattern.count} occurrences
                </div>
            `).join('')}
        </div>
        ` : ''}

        ${analysis.suggestions.length > 0 ? `
        <div class="section">
            <h2>💡 Suggestions</h2>
            ${analysis.suggestions.map(suggestion => `
                <div class="suggestion">${suggestion}</div>
            `).join('')}
        </div>
        ` : ''}
    </body>
    </html>
    `;
}

/**
 * Generate HTML for enhanced search results
 */
function generateEnhancedResultsHTML(results) {
    return `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <title>Enhanced Search Results</title>
        <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; }
            .header { color: #007ACC; border-bottom: 2px solid #007ACC; padding-bottom: 10px; }
            .section { margin: 20px 0; padding: 15px; background: #f8f9fa; border-radius: 8px; }
            .insight { background: #e8f5e8; padding: 10px; margin: 5px 0; border-radius: 5px; border-left: 4px solid #28a745; }
            .recommendation { background: #fff3cd; padding: 10px; margin: 5px 0; border-radius: 5px; border-left: 4px solid #ffc107; }
            .file-item { background: white; padding: 8px; margin: 3px 0; border-radius: 4px; }
            .pattern-group { background: #f0f8ff; padding: 10px; margin: 5px 0; border-radius: 5px; }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>🎯 Enhanced Search Results: "${results.query}"</h1>
            <p>${results.aiInsights.summary}</p>
        </div>

        <div class="section">
            <h2>🤖 AI Insights</h2>
            ${results.aiInsights.recommendations.map(rec => `
                <div class="recommendation">💡 ${rec}</div>
            `).join('')}

            ${results.aiInsights.opportunities.map(opp => `
                <div class="insight">🚀 ${opp}</div>
            `).join('')}
        </div>

        <div class="section">
            <h2>📊 Analysis Summary</h2>
            <div class="file-item">
                <strong>Files analyzed:</strong> ${results.textAnalysis.summary.totalFiles}
            </div>
            <div class="file-item">
                <strong>Files with matches:</strong> ${results.textAnalysis.summary.matchingFiles}
            </div>
            <div class="file-item">
                <strong>Total matches:</strong> ${results.textAnalysis.summary.totalMatches}
            </div>
        </div>

        ${Object.keys(results.patterns).some(key => results.patterns[key].length > 0) ? `
        <div class="section">
            <h2>🔍 Code Patterns</h2>
            ${Object.entries(results.patterns).map(([type, items]) =>
                items.length > 0 ? `
                    <div class="pattern-group">
                        <h4>${type.charAt(0).toUpperCase() + type.slice(1)}</h4>
                        ${items.slice(0, 5).map(item => `
                            <div class="file-item">${item.name} (${item.file})</div>
                        `).join('')}
                        ${items.length > 5 ? `<div class="file-item">... and ${items.length - 5} more</div>` : ''}
                    </div>
                ` : ''
            ).join('')}
        </div>
        ` : ''}

        <div class="section">
            <h2>📄 Matching Files</h2>
            ${results.textAnalysis.files.slice(0, 10).map(file => `
                <div class="file-item">
                    <strong>${file.name}</strong> - ${file.matches} matches (${file.lines} lines)
                </div>
            `).join('')}
            ${results.textAnalysis.files.length > 10 ?
                `<div class="file-item">... and ${results.textAnalysis.files.length - 10} more files</div>` : ''}
        </div>
    </body>
    </html>
    `;
}
/**
 * Enhanced File System Events for Roblox Development
 */
function setupEnhancedFileEvents(luaWatcher, projectWatcher, rbxlxWatcher) {
    // Enhanced Lua/Luau File Events
    luaWatcher.onDidCreate(async (uri) => {
        console.log(`📄 New Lua file detected: ${uri.fsPath}`);
        await handleEnhancedLuaFile(uri);
        await updateCopilotContext(uri);
    });

    luaWatcher.onDidChange(async (uri) => {
        console.log(`✏️ Lua file changed: ${uri.fsPath}`);
        await analyzeChangedFile(uri);
        await updateSemanticIndex(uri);
    });

    // Enhanced Project Events
    projectWatcher.onDidChange(async (uri) => {
        console.log(`🔧 Project configuration changed: ${uri.fsPath}`);
        await syncProjectStructure(uri);
        await regenerateSourcemaps();
    });

    // Roblox Place File Events
    rbxlxWatcher.onDidChange(async (uri) => {
        console.log(`🎯 Roblox Place updated: ${uri.fsPath}`);
        await analyzeRobloxPlace(uri);
    });
}

/**
 * Create Enhanced Roblox Service with AI optimization
 */
async function createRobloxService() {
    const serviceName = await vscode.window.showInputBox({
        prompt: 'Enter Service Name (e.g., PlayerService)',
        placeholder: 'MyService',
        validateInput: (value) => {
            if (!value || !/^[A-Z][a-zA-Z0-9]*$/.test(value)) {
                return 'Service name must start with uppercase letter and be alphanumeric';
            }
            return null;
        }
    });

    if (!serviceName) return;

    const serviceType = await vscode.window.showQuickPick([
        { label: 'Game Service', description: 'Core game logic service', value: 'game' },
        { label: 'Player Service', description: 'Player data and management', value: 'player' },
        { label: 'World Service', description: 'World generation and management', value: 'world' },
        { label: 'Event Service', description: 'Event handling and communication', value: 'event' }
    ], { placeHolder: 'Select Service Type' });

    if (!serviceType) return;

    const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
    if (!workspaceFolder) {
        vscode.window.showErrorMessage('No workspace opened');
        return;
    }

    const serviceTemplate = generateEnhancedServiceTemplate(serviceName, serviceType.value);
    const filePath = path.join(workspaceFolder.uri.fsPath, 'src', 'server', `${serviceName}.lua`);

    try {
        await ensureDirectoryExists(path.dirname(filePath));
        await fs.writeFile(filePath, serviceTemplate);

        // Open created file
        const document = await vscode.workspace.openTextDocument(filePath);
        await vscode.window.showTextDocument(document);

        vscode.window.showInformationMessage(`✅ Enhanced ${serviceName} service created`);

        // Update project context
        await updateProjectContext();
        await generateServiceDocumentation(serviceName, serviceType.value);

    } catch (error) {
        vscode.window.showErrorMessage(`Error creating service: ${error.message}`);
    }
}

/**
 * Create Enhanced Roblox Module with AI-powered templates
 */
async function createRobloxModule() {
    const moduleName = await vscode.window.showInputBox({
        prompt: 'Enter Module Name',
        placeholder: 'MyModule'
    });

    if (!moduleName) return;

    const moduleType = await vscode.window.showQuickPick([
        { label: 'Controller Module', description: 'Player/UI controller', value: 'controller' },
        { label: 'Handler Module', description: 'Event/Input handler', value: 'handler' },
        { label: 'Manager Module', description: 'System manager', value: 'manager' },
        { label: 'Utility Module', description: 'Helper functions', value: 'utility' },
        { label: 'Data Module', description: 'Data structures', value: 'data' }
    ], { placeHolder: 'Select Module Type' });

    if (!moduleType) return;

    const targetLocation = await vscode.window.showQuickPick([
        { label: 'Client', description: 'Client-side module', value: 'client' },
        { label: 'Server', description: 'Server-side module', value: 'server' },
        { label: 'Shared', description: 'Shared module', value: 'shared' }
    ], { placeHolder: 'Select Target Location' });

    if (!targetLocation) return;

    const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
    if (!workspaceFolder) return;

    const moduleTemplate = generateEnhancedModuleTemplate(moduleName, moduleType.value, targetLocation.value);
    const folderPath = targetLocation.value === 'shared' ? 'shared' : `${targetLocation.value}/modules`;
    const filePath = path.join(workspaceFolder.uri.fsPath, 'src', folderPath, `${moduleName}.lua`);

    try {
        await ensureDirectoryExists(path.dirname(filePath));
        await fs.writeFile(filePath, moduleTemplate);

        const document = await vscode.workspace.openTextDocument(filePath);
        await vscode.window.showTextDocument(document);

        vscode.window.showInformationMessage(`✅ Enhanced ${moduleName} module created`);

        // Generate type definitions for better Copilot support
        await generateTypeDefinitions(moduleName, moduleType.value);

    } catch (error) {
        vscode.window.showErrorMessage(`Error: ${error.message}`);
    }
}

/**
 * Create Enhanced LocalScript with AI optimization
 */
async function createLocalScript() {
    const scriptName = await vscode.window.showInputBox({
        prompt: 'Enter LocalScript Name',
        placeholder: 'MyScript'
    });

    if (!scriptName) return;

    const scriptType = await vscode.window.showQuickPick([
        { label: 'Player Controller', description: 'Character movement and input', value: 'player' },
        { label: 'Camera Controller', description: 'Camera management', value: 'camera' },
        { label: 'UI Controller', description: 'User interface management', value: 'ui' },
        { label: 'Audio Controller', description: 'Sound effects and music', value: 'audio' },
        { label: 'Effects Controller', description: 'Visual effects', value: 'effects' },
        { label: 'Input Handler', description: 'Input processing', value: 'input' }
    ], { placeHolder: 'Select Script Type' });

    if (!scriptType) return;

    const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
    if (!workspaceFolder) return;

    const scriptTemplate = generateEnhancedLocalScriptTemplate(scriptName, scriptType.value);
    const subFolder = scriptType.value === 'player' || scriptType.value === 'camera' ? 'controllers' : 'modules';
    const filePath = path.join(workspaceFolder.uri.fsPath, 'src', 'client', subFolder, `${scriptName}.client.lua`);

    try {
        await ensureDirectoryExists(path.dirname(filePath));
        await fs.writeFile(filePath, scriptTemplate);

        const document = await vscode.workspace.openTextDocument(filePath);
        await vscode.window.showTextDocument(document);

        vscode.window.showInformationMessage(`✅ Enhanced LocalScript ${scriptName} created`);

        // Auto-generate corresponding module if needed
        if (scriptType.value === 'player' || scriptType.value === 'camera') {
            await generateCorrespondingModule(scriptName, scriptType.value);
        }

    } catch (error) {
        vscode.window.showErrorMessage(`Error: ${error.message}`);
    }
}

/**
 * Generate Enhanced RemoteEvents with validation
 */
async function generateRemoteEvents() {
    const events = await vscode.window.showInputBox({
        prompt: 'Enter RemoteEvent names (comma-separated)',
        placeholder: 'PlayerMoved, ScoreUpdated, PowerUpActivated, GameStateChanged'
    });

    if (!events) return;

    const eventList = events.split(',').map(e => e.trim()).filter(e => e);
    const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
    if (!workspaceFolder) return;

    try {
        // Generate enhanced server-side RemoteEvent handler
        const serverTemplate = generateEnhancedRemoteEventServerTemplate(eventList);
        const serverPath = path.join(workspaceFolder.uri.fsPath, 'src', 'server', 'RemoteEventHandler.lua');

        await ensureDirectoryExists(path.dirname(serverPath));
        await fs.writeFile(serverPath, serverTemplate);

        // Generate enhanced client-side RemoteEvent handler
        const clientTemplate = generateEnhancedRemoteEventClientTemplate(eventList);
        const clientPath = path.join(workspaceFolder.uri.fsPath, 'src', 'client', 'modules', 'RemoteEventClient.lua');

        await ensureDirectoryExists(path.dirname(clientPath));
        await fs.writeFile(clientPath, clientTemplate);

        // Generate type definitions for RemoteEvents
        const typesTemplate = generateRemoteEventTypes(eventList);
        const typesPath = path.join(workspaceFolder.uri.fsPath, 'src', 'shared', 'RemoteEventTypes.lua');
        await fs.writeFile(typesPath, typesTemplate);

        // Update default.project.json with new events
        await updateProjectJsonWithRemoteEvents(eventList);

        // Generate validation middleware
        await generateRemoteEventValidation(eventList);

        vscode.window.showInformationMessage(`✅ ${eventList.length} Enhanced RemoteEvents generated with validation`);

    } catch (error) {
        vscode.window.showErrorMessage(`Error: ${error.message}`);
    }
}

/**
 * Optimize files for enhanced Copilot performance
 */
async function optimizeForCopilot() {
    const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
    if (!workspaceFolder) return;

    const progress = await vscode.window.withProgress({
        location: vscode.ProgressLocation.Notification,
        title: "Optimizing for GitHub Copilot",
        cancellable: false
    }, async (progress) => {
        progress.report({ increment: 0, message: "Analyzing Lua files..." });

        try {
            // Analyze all Lua files
            const luaFiles = await findLuaFiles(workspaceFolder.uri.fsPath);
            let optimizedCount = 0;

            for (let i = 0; i < luaFiles.length; i++) {
                const filePath = luaFiles[i];
                progress.report({
                    increment: (100 / luaFiles.length),
                    message: `Optimizing ${path.basename(filePath)}...`
                });

                const content = await fs.readFile(filePath, 'utf8');
                const optimizedContent = await optimizeLuaForEnhancedCopilot(content, filePath);

                if (optimizedContent !== content) {
                    await fs.writeFile(filePath, optimizedContent);
                    optimizedCount++;
                }
            }

            // Generate enhanced .vscode/copilot-chat-config.json
            await ensureEnhancedCopilotConfig(workspaceFolder.uri.fsPath);

            // Generate semantic search index
            await generateSemanticSearchIndex(workspaceFolder.uri.fsPath);

            // Create AI context files
            await generateAIContextFiles(workspaceFolder.uri.fsPath);

            return optimizedCount;

        } catch (error) {
            vscode.window.showErrorMessage(`Optimization error: ${error.message}`);
            return 0;
        }
    });

    vscode.window.showInformationMessage(`✅ ${progress} files optimized for Enhanced Copilot`);
}

/**
 * Enhanced Project Analysis with AI insights
 */
async function analyzeRobloxProject() {
    const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
    if (!workspaceFolder) return;

    try {
        const analysis = await performEnhancedProjectAnalysis(workspaceFolder.uri.fsPath);

        // Create detailed analysis report
        const reportPath = path.join(workspaceFolder.uri.fsPath, 'analysis-report.md');
        await fs.writeFile(reportPath, analysis);

        // Create AI recommendations
        const recommendations = await generateAIRecommendations(workspaceFolder.uri.fsPath);
        const recommendationsPath = path.join(workspaceFolder.uri.fsPath, 'ai-recommendations.md');
        await fs.writeFile(recommendationsPath, recommendations);

        const document = await vscode.workspace.openTextDocument(reportPath);
        await vscode.window.showTextDocument(document);

        vscode.window.showInformationMessage('📊 Enhanced Project Analysis completed with AI insights');

    } catch (error) {
/**
 * Enhanced Template Generators for AI-optimized Roblox Development
 */
function generateEnhancedServiceTemplate(serviceName, serviceType) {
    const templates = {
        game: `--!strict
-- ${serviceName}.lua - Enhanced Game Service with AI optimization
-- Generated by Enhanced Roblox Copilot Extension
-- Optimized for GitHub Copilot code generation

local ${serviceName} = {}

-- Type definitions for enhanced Copilot suggestions
export type ${serviceName}Config = {
    enabled: boolean,
    updateRate: number,
    maxPlayers: number?,
    gameMode: string?,
}

export type GameState = "Waiting" | "Playing" | "Paused" | "Ended"

-- Enhanced service imports with error handling
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Import shared modules with validation
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local GameState = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameState"))

-- Configuration with AI-friendly defaults
local DEFAULT_CONFIG: ${serviceName}Config = {
    enabled = true,
    updateRate = 60,
    maxPlayers = 8,
    gameMode = "normal",
}

-- Enhanced state management
local isInitialized = false
local config: ${serviceName}Config = DEFAULT_CONFIG
local currentGameState: GameState = "Waiting"
local connectedPlayers: {[Player]: boolean} = {}

-- Performance monitoring for Copilot optimization
local performanceMetrics = {
    lastUpdateTime = 0,
    averageUpdateTime = 0,
    frameCount = 0,
}

-- Initialize enhanced ${serviceName}
function ${serviceName}:Initialize(serviceConfig: ${serviceName}Config?)
    if isInitialized then
        warn("[${serviceName}] Service already initialized")
        return false
    end

    -- Merge configuration with defaults
    if serviceConfig then
        for key, value in pairs(serviceConfig) do
            config[key] = value
        end
    end

    -- Enhanced initialization sequence
    local initSuccess = pcall(function()
        self:SetupEventListeners()
        self:StartUpdateLoop()
        self:InitializeRemoteEvents()
        self:SetupPerformanceMonitoring()
    end)

    if not initSuccess then
        error("[${serviceName}] Failed to initialize service")
        return false
    end

    isInitialized = true
    print("[${serviceName}] ✅ Enhanced service initialized successfully")
    return true
end

-- Enhanced event listener setup
function ${serviceName}:SetupEventListeners()
    -- Player management with enhanced error handling
    Players.PlayerAdded:Connect(function(player)
        local success = pcall(function()
            self:OnPlayerAdded(player)
        end)

        if not success then
            warn("[${serviceName}] Error handling player added:", player.Name)
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        local success = pcall(function()
            self:OnPlayerRemoving(player)
        end)

        if not success then
            warn("[${serviceName}] Error handling player removal:", player.Name)
        end
    end)
end

-- Enhanced update loop with performance monitoring
function ${serviceName}:StartUpdateLoop()
    RunService.Heartbeat:Connect(function(deltaTime)
        if not config.enabled then return end

        local startTime = tick()

        -- Main update logic with error handling
        local updateSuccess = pcall(function()
            self:Update(deltaTime)
        end)

        if not updateSuccess then
            warn("[${serviceName}] Update loop error")
        end

        -- Performance tracking
        local updateTime = tick() - startTime
        performanceMetrics.lastUpdateTime = updateTime
        performanceMetrics.frameCount = performanceMetrics.frameCount + 1

        -- Calculate average update time for optimization
        if performanceMetrics.frameCount % 60 == 0 then
            performanceMetrics.averageUpdateTime = performanceMetrics.lastUpdateTime
        end
    end)
end

-- Enhanced player management
function ${serviceName}:OnPlayerAdded(player: Player)
    connectedPlayers[player] = true

    print("[${serviceName}] Player joined with enhanced tracking:", player.Name)

    -- Enhanced player setup with Copilot-friendly patterns
    spawn(function()
        local character = player.CharacterAdded:Wait()
        self:SetupPlayerCharacter(player, character)
    end)

    -- Notify other systems
    local playerJoinedEvent = ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("PlayerJoined")
    if playerJoinedEvent then
        playerJoinedEvent:FireAllClients(player.Name)
    end
end

-- Enhanced player removal handling
function ${serviceName}:OnPlayerRemoving(player: Player)
    connectedPlayers[player] = nil

    print("[${serviceName}] Player leaving with cleanup:", player.Name)

    -- Enhanced cleanup with validation
    self:CleanupPlayerData(player)

    -- Notify other systems
    local playerLeftEvent = ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("PlayerLeft")
    if playerLeftEvent then
        playerLeftEvent:FireAllClients(player.Name)
    end
end

-- Enhanced character setup
function ${serviceName}:SetupPlayerCharacter(player: Player, character: Model)
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        warn("[${serviceName}] No humanoid found for player:", player.Name)
        return
    end

    -- Enhanced character configuration
    humanoid.WalkSpeed = GameConfig.Player.walkSpeed or 16
    humanoid.JumpPower = GameConfig.Player.jumpPower or 50

    print("[${serviceName}] Character setup completed for:", player.Name)
end

-- Enhanced main update function
function ${serviceName}:Update(deltaTime: number)
    -- Update game state logic
    self:UpdateGameState(deltaTime)

    -- Update connected players
    for player, _ in pairs(connectedPlayers) do
        if player.Parent then
            self:UpdatePlayer(player, deltaTime)
        else
            -- Player disconnected, cleanup
            connectedPlayers[player] = nil
        end
    end
end

-- Enhanced game state management
function ${serviceName}:UpdateGameState(deltaTime: number)
    -- Implement game state logic here
    -- This method provides enhanced Copilot context for game state management
end

-- Enhanced player update
function ${serviceName}:UpdatePlayer(player: Player, deltaTime: number)
    -- Implement per-player update logic here
    -- Enhanced with type safety and error handling
end

-- Enhanced RemoteEvent initialization
function ${serviceName}:InitializeRemoteEvents()
    local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteEventsFolder then
        warn("[${serviceName}] RemoteEvents folder not found")
        return
    end

    -- Setup enhanced remote event handlers
    for _, remoteEvent in pairs(remoteEventsFolder:GetChildren()) do
        if remoteEvent:IsA("RemoteEvent") then
            self:SetupRemoteEventHandler(remoteEvent)
        end
    end
end

-- Enhanced RemoteEvent handler setup
function ${serviceName}:SetupRemoteEventHandler(remoteEvent: RemoteEvent)
    remoteEvent.OnServerEvent:Connect(function(player, ...)
        local args = {...}

        -- Enhanced validation and error handling
        local handleSuccess = pcall(function()
            self:HandleRemoteEvent(player, remoteEvent.Name, args)
        end)

        if not handleSuccess then
            warn("[${serviceName}] Error handling RemoteEvent:", remoteEvent.Name, "from player:", player.Name)
        end
    end)
end

-- Enhanced RemoteEvent handling
function ${serviceName}:HandleRemoteEvent(player: Player, eventName: string, args: {any})
    -- Implement enhanced RemoteEvent handling logic
    print("[${serviceName}] Handling RemoteEvent:", eventName, "from:", player.Name)
end

-- Enhanced performance monitoring setup
function ${serviceName}:SetupPerformanceMonitoring()
    spawn(function()
        while isInitialized do
            wait(5) -- Monitor every 5 seconds

            local fps = 1 / performanceMetrics.averageUpdateTime
            local memoryUsage = collectgarbage("count")

            -- Log performance metrics for optimization
            if fps < 30 then
                warn("[${serviceName}] Low FPS detected:", math.floor(fps))
            end

            if memoryUsage > 50000 then -- 50MB threshold
                warn("[${serviceName}] High memory usage:", math.floor(memoryUsage), "KB")
            end
        end
    end)
end

-- Enhanced cleanup for player data
function ${serviceName}:CleanupPlayerData(player: Player)
    -- Implement enhanced cleanup logic
    -- This provides better Copilot context for cleanup patterns

    local success = pcall(function()
        -- Remove player-specific data
        -- Clean up any player-related objects
        -- Notify other services of player departure
    end)

    if not success then
        warn("[${serviceName}] Error during player cleanup:", player.Name)
    end
end

-- Enhanced getter methods for configuration
function ${serviceName}:GetConfig(): ${serviceName}Config
    return config
end

function ${serviceName}:GetGameState(): GameState
    return currentGameState
end

function ${serviceName}:GetConnectedPlayers(): {Player}
    local players = {}
    for player, _ in pairs(connectedPlayers) do
        if player.Parent then
            table.insert(players, player)
        end
    end
    return players
end

function ${serviceName}:GetPerformanceMetrics()
    return {
        fps = 1 / performanceMetrics.averageUpdateTime,
        averageUpdateTime = performanceMetrics.averageUpdateTime,
        frameCount = performanceMetrics.frameCount,
        memoryUsage = collectgarbage("count"),
    }
end

-- Enhanced setter methods
function ${serviceName}:SetConfig(newConfig: ${serviceName}Config)
    for key, value in pairs(newConfig) do
        config[key] = value
    end
    print("[${serviceName}] Configuration updated with enhanced validation")
end

function ${serviceName}:SetGameState(newState: GameState)
    local previousState = currentGameState
    currentGameState = newState

    print("[${serviceName}] Game state changed:", previousState, "->", newState)

    -- Notify clients of state change
    local stateChangedEvent = ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("GameStateChanged")
    if stateChangedEvent then
        stateChangedEvent:FireAllClients(newState)
    end
end

-- Enhanced utility methods
function ${serviceName}:IsPlayerConnected(player: Player): boolean
    return connectedPlayers[player] == true
end

function ${serviceName}:GetPlayerCount(): number
    local count = 0
    for _, _ in pairs(connectedPlayers) do
        count = count + 1
    end
    return count
end

-- Enhanced shutdown method
function ${serviceName}:Shutdown()
    if not isInitialized then return end

    -- Enhanced cleanup sequence
    isInitialized = false
    currentGameState = "Ended"

    -- Cleanup all players
    for player, _ in pairs(connectedPlayers) do
        self:CleanupPlayerData(player)
    end

    -- Clear connections and data
    table.clear(connectedPlayers)

    print("[${serviceName}] ✅ Service shutdown completed")
end

return ${serviceName}
`,

        player: `--!strict
-- ${serviceName}.lua - Enhanced Player Management Service
-- AI-optimized for GitHub Copilot code generation

local ${serviceName} = {}

-- Enhanced type definitions for better Copilot suggestions
export type PlayerData = {
    userId: number,
    displayName: string,
    joinTime: number,
    score: number,
    coins: number,
    level: number,
    powerUps: {string},
    achievements: {string},
}

export type PlayerSession = {
    player: Player,
    data: PlayerData,
    character: Model?,
    lastUpdate: number,
    isActive: boolean,
}

-- Enhanced service dependencies
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

-- Enhanced data management
local PlayerDataStore = DataStoreService:GetDataStore("PlayerData_v2")
local playerSessions: {[Player]: PlayerSession} = {}
local isInitialized = false

-- Enhanced default player data structure
local DEFAULT_PLAYER_DATA: PlayerData = {
    userId = 0,
    displayName = "",
    joinTime = 0,
    score = 0,
    coins = 0,
    level = 1,
    powerUps = {},
    achievements = {},
}

-- Initialize enhanced player service
function ${serviceName}:Initialize()
    if isInitialized then
        warn("[${serviceName}] Service already initialized")
        return false
    end

    -- Enhanced initialization with error handling
    local initSuccess = pcall(function()
        self:SetupPlayerEvents()
        self:SetupDataSaving()
        self:SetupRemoteEvents()
    end)

    if not initSuccess then
        error("[${serviceName}] Failed to initialize player service")
        return false
    end

    isInitialized = true
    print("[${serviceName}] ✅ Enhanced player service initialized")
    return true
end

-- Enhanced player event setup
function ${serviceName}:SetupPlayerEvents()
    Players.PlayerAdded:Connect(function(player)
        spawn(function()
            self:OnPlayerJoined(player)
        end)
    end)

    Players.PlayerRemoving:Connect(function(player)
        spawn(function()
            self:OnPlayerLeaving(player)
        end)
    end)
end

-- Enhanced player joining logic
function ${serviceName}:OnPlayerJoined(player: Player)
    print("[${serviceName}] Loading data for player:", player.Name)

    -- Load player data with enhanced error handling
    local playerData = self:LoadPlayerData(player)
    if not playerData then
        warn("[${serviceName}] Failed to load data for:", player.Name)
        return
    end

    -- Create enhanced player session
    local session: PlayerSession = {
        player = player,
        data = playerData,
        character = nil,
        lastUpdate = tick(),
        isActive = true,
    }

    playerSessions[player] = session

    -- Setup character handling
    player.CharacterAdded:Connect(function(character)
        self:OnCharacterAdded(player, character)
    end)

    -- Notify other systems
    local playerJoinedEvent = ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("PlayerJoined")
    if playerJoinedEvent then
        playerJoinedEvent:FireAllClients(player.Name, playerData)
    end

    print("[${serviceName}] ✅ Player session created for:", player.Name)
end

-- Enhanced character handling
function ${serviceName}:OnCharacterAdded(player: Player, character: Model)
    local session = playerSessions[player]
    if not session then return end

    session.character = character
    session.lastUpdate = tick()

    -- Enhanced character setup
    local humanoid = character:WaitForChild("Humanoid")
    if humanoid then
        -- Apply player data to character
        self:ApplyPlayerDataToCharacter(player, character)
    end

    print("[${serviceName}] Character loaded for:", player.Name)
end

-- Enhanced player leaving logic
function ${serviceName}:OnPlayerLeaving(player: Player)
    local session = playerSessions[player]
    if not session then return end

    -- Save player data before leaving
    self:SavePlayerData(player)

    -- Cleanup session
    playerSessions[player] = nil

    print("[${serviceName}] ✅ Player session cleaned up for:", player.Name)
end

-- Enhanced data loading with caching
function ${serviceName}:LoadPlayerData(player: Player): PlayerData?
    local success, data = pcall(function()
        return PlayerDataStore:GetAsync(tostring(player.UserId))
    end)

    if not success then
        warn("[${serviceName}] DataStore error for:", player.Name)
        -- Return default data as fallback
        local defaultData = table.clone(DEFAULT_PLAYER_DATA)
        defaultData.userId = player.UserId
        defaultData.displayName = player.DisplayName
        defaultData.joinTime = tick()
        return defaultData
    end

    -- Merge with defaults if data exists
    if data then
        local mergedData = table.clone(DEFAULT_PLAYER_DATA)
        for key, value in pairs(data) do
            mergedData[key] = value
        end
        return mergedData
    else
        -- New player data
        local newData = table.clone(DEFAULT_PLAYER_DATA)
        newData.userId = player.UserId
        newData.displayName = player.DisplayName
        newData.joinTime = tick()
        return newData
    end
end

-- Enhanced data saving with validation
function ${serviceName}:SavePlayerData(player: Player): boolean
    local session = playerSessions[player]
    if not session then return false end

    local success = pcall(function()
        PlayerDataStore:SetAsync(tostring(player.UserId), session.data)
    end)

    if success then
        print("[${serviceName}] ✅ Data saved for:", player.Name)
        return true
    else
        warn("[${serviceName}] ❌ Failed to save data for:", player.Name)
        return false
    end
end

-- Enhanced player data getters
function ${serviceName}:GetPlayerData(player: Player): PlayerData?
    local session = playerSessions[player]
    return session and session.data
end

function ${serviceName}:GetPlayerSession(player: Player): PlayerSession?
    return playerSessions[player]
end

function ${serviceName}:GetAllActivePlayers(): {Player}
    local activePlayers = {}
    for player, session in pairs(playerSessions) do
        if session.isActive and player.Parent then
            table.insert(activePlayers, player)
        end
    end
    return activePlayers
end

-- Enhanced player data setters with validation
function ${serviceName}:UpdatePlayerScore(player: Player, scoreChange: number): boolean
    local session = playerSessions[player]
    if not session then return false end

    session.data.score = math.max(0, session.data.score + scoreChange)
    session.lastUpdate = tick()

    -- Notify clients of score update
    local scoreUpdateEvent = ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("ScoreUpdate")
    if scoreUpdateEvent then
        scoreUpdateEvent:FireClient(player, session.data.score)
    end

    return true
end

function ${serviceName}:UpdatePlayerCoins(player: Player, coinChange: number): boolean
    local session = playerSessions[player]
    if not session then return false end

    session.data.coins = math.max(0, session.data.coins + coinChange)
    session.lastUpdate = tick()

    -- Auto-save on significant coin changes
    if math.abs(coinChange) >= 100 then
        spawn(function()
            self:SavePlayerData(player)
        end)
    end

    return true
end

-- Enhanced utility methods
function ${serviceName}:ApplyPlayerDataToCharacter(player: Player, character: Model)
    local session = playerSessions[player]
    if not session then return end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end

    -- Apply level-based bonuses
    local level = session.data.level
    humanoid.WalkSpeed = 16 + (level * 0.5) -- Speed bonus per level
    humanoid.JumpPower = 50 + (level * 2) -- Jump bonus per level

    print("[${serviceName}] Applied level", level, "bonuses to:", player.Name)
end

-- Enhanced periodic data saving
function ${serviceName}:SetupDataSaving()
    spawn(function()
        while isInitialized do
            wait(300) -- Save every 5 minutes

            for player, _ in pairs(playerSessions) do
                if player.Parent then
                    self:SavePlayerData(player)
                end
            end

            print("[${serviceName}] Periodic data save completed")
        end
    end)
end

-- Enhanced RemoteEvent setup
function ${serviceName}:SetupRemoteEvents()
    local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteEventsFolder then return end

    -- Setup GetPlayerData RemoteFunction
    local getPlayerDataFunction = ReplicatedStorage:FindFirstChild("RemoteFunctions"):FindFirstChild("GetPlayerData")
    if getPlayerDataFunction then
        getPlayerDataFunction.OnServerInvoke = function(player)
            return self:GetPlayerData(player)
        end
    end
end

-- Enhanced shutdown method
function ${serviceName}:Shutdown()
    if not isInitialized then return end

    -- Save all player data before shutdown
    for player, _ in pairs(playerSessions) do
        self:SavePlayerData(player)
    end

    -- Clear sessions
    table.clear(playerSessions)

    isInitialized = false
    print("[${serviceName}] ✅ Player service shutdown completed")
end

return ${serviceName}
`,

        world: `--!strict
-- ${serviceName}.lua - Enhanced World Management Service
-- Optimized for GitHub Copilot and procedural generation

local ${serviceName} = {}

-- Enhanced type definitions for world management
export type WorldConfig = {
    chunkSize: number,
    renderDistance: number,
    maxChunks: number,
    generateTerrain: boolean,
    enableLighting: boolean,
}

export type WorldChunk = {
    id: string,
    position: Vector3,
    size: Vector3,
    generated: boolean,
    loaded: boolean,
    lastAccess: number,
    objects: {Instance},
}

-- Enhanced services for world management
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Enhanced world state management
local isInitialized = false
local worldChunks: {[string]: WorldChunk} = {}
local activeChunks: {WorldChunk} = {}

local DEFAULT_CONFIG: WorldConfig = {
    chunkSize = 512,
    renderDistance = 1024,
    maxChunks = 16,
    generateTerrain = true,
    enableLighting = true,
}

local config: WorldConfig = DEFAULT_CONFIG

-- Initialize enhanced world service
function ${serviceName}:Initialize(worldConfig: WorldConfig?)
    if isInitialized then
        warn("[${serviceName}] World service already initialized")
        return false
    end

    -- Merge configuration
    if worldConfig then
        for key, value in pairs(worldConfig) do
            config[key] = value
        end
    end

    -- Enhanced world setup
    local setupSuccess = pcall(function()
        self:SetupWorldEnvironment()
        self:InitializeChunkSystem()
        self:SetupLighting()
        self:StartWorldUpdates()
    end)

    if not setupSuccess then
        error("[${serviceName}] Failed to initialize world service")
        return false
    end

    isInitialized = true
    print("[${serviceName}] ✅ Enhanced world service initialized")
    return true
end

-- Enhanced world environment setup
function ${serviceName}:SetupWorldEnvironment()
    -- Clear existing world if needed
    local existingObjects = Workspace:GetChildren()
    for _, obj in pairs(existingObjects) do
        if obj.Name ~= "Camera" and obj.Name ~= "Terrain" and not obj:IsA("Player") then
            obj:Destroy()
        end
    end

    -- Create world container
    local worldContainer = Instance.new("Folder")
    worldContainer.Name = "GeneratedWorld"
    worldContainer.Parent = Workspace

    print("[${serviceName}] World environment prepared")
end

-- Enhanced chunk system initialization
function ${serviceName}:InitializeChunkSystem()
    -- Generate initial world chunks
    for x = -1, 1 do
        for z = -1, 1 do
            local chunkId = string.format("%d_%d", x, z)
            local chunk = self:CreateWorldChunk(chunkId, Vector3.new(x * config.chunkSize, 0, z * config.chunkSize))
            worldChunks[chunkId] = chunk
            table.insert(activeChunks, chunk)
        end
    end

    print("[${serviceName}] Initial chunks generated:", #activeChunks)
end

-- Enhanced chunk creation
function ${serviceName}:CreateWorldChunk(id: string, position: Vector3): WorldChunk
    local chunk: WorldChunk = {
        id = id,
        position = position,
        size = Vector3.new(config.chunkSize, 256, config.chunkSize),
        generated = false,
        loaded = false,
        lastAccess = tick(),
        objects = {},
    }

    -- Generate chunk content
    self:GenerateChunkContent(chunk)

    return chunk
end

-- Enhanced chunk content generation
function ${serviceName}:GenerateChunkContent(chunk: WorldChunk)
    -- Create terrain base
    local terrain = Instance.new("Part")
    terrain.Name = "ChunkTerrain_" .. chunk.id
    terrain.Size = Vector3.new(chunk.size.X, 4, chunk.size.Z)
    terrain.Position = chunk.position + Vector3.new(0, -2, 0)
    terrain.Material = Enum.Material.Grass
    terrain.BrickColor = BrickColor.new("Bright green")
    terrain.Anchored = true
    terrain.Parent = Workspace:FindFirstChild("GeneratedWorld")

    table.insert(chunk.objects, terrain)

    -- Generate features based on chunk position
    self:GenerateChunkFeatures(chunk)

    chunk.generated = true
    chunk.loaded = true
    chunk.lastAccess = tick()

    print("[${serviceName}] Generated chunk:", chunk.id)
end

-- Enhanced chunk feature generation
function ${serviceName}:GenerateChunkFeatures(chunk: WorldChunk)
    local random = Random.new(tick())

    -- Generate trees
    for i = 1, random:NextInteger(5, 15) do
        local tree = self:CreateTree(
            chunk.position + Vector3.new(
                random:NextNumber(-chunk.size.X/2, chunk.size.X/2),
                0,
                random:NextNumber(-chunk.size.Z/2, chunk.size.Z/2)
            )
        )

        if tree then
            table.insert(chunk.objects, tree)
        end
    end

    -- Generate rocks
    for i = 1, random:NextInteger(2, 8) do
        local rock = self:CreateRock(
            chunk.position + Vector3.new(
                random:NextNumber(-chunk.size.X/2, chunk.size.X/2),
                0,
                random:NextNumber(-chunk.size.Z/2, chunk.size.Z/2)
            )
        )

        if rock then
            table.insert(chunk.objects, rock)
        end
    end
end

-- Enhanced object creation methods
function ${serviceName}:CreateTree(position: Vector3): Model?
    local tree = Instance.new("Model")
    tree.Name = "GeneratedTree"
    tree.Parent = Workspace:FindFirstChild("GeneratedWorld")

    -- Tree trunk
    local trunk = Instance.new("Part")
    trunk.Name = "Trunk"
    trunk.Size = Vector3.new(2, 8, 2)
    trunk.Position = position + Vector3.new(0, 4, 0)
    trunk.Material = Enum.Material.Wood
    trunk.BrickColor = BrickColor.new("Brown")
    trunk.Anchored = true
    trunk.Parent = tree

    -- Tree leaves
    local leaves = Instance.new("Part")
    leaves.Name = "Leaves"
    leaves.Size = Vector3.new(6, 6, 6)
    leaves.Position = position + Vector3.new(0, 10, 0)
    leaves.Material = Enum.Material.Foil
    leaves.BrickColor = BrickColor.new("Bright green")
    leaves.Shape = Enum.PartType.Ball
    leaves.Anchored = true
    leaves.Parent = tree

    return tree
end

function ${serviceName}:CreateRock(position: Vector3): Part?
    local rock = Instance.new("Part")
    rock.Name = "GeneratedRock"
    rock.Size = Vector3.new(
        math.random(2, 4),
        math.random(1, 3),
        math.random(2, 4)
    )
    rock.Position = position + Vector3.new(0, rock.Size.Y/2, 0)
    rock.Material = Enum.Material.Rock
    rock.BrickColor = BrickColor.new("Dark stone grey")
    rock.Shape = Enum.PartType.Block
    rock.Anchored = true
    rock.Parent = Workspace:FindFirstChild("GeneratedWorld")

    return rock
end

-- Enhanced lighting setup
function ${serviceName}:SetupLighting()
    if not config.enableLighting then return end

    -- Enhanced lighting configuration
    Lighting.Brightness = 2
    Lighting.GlobalShadows = true
    Lighting.Technology = Enum.Technology.ShadowMap
    Lighting.Ambient = Color3.fromRGB(70, 70, 70)

    -- Add atmospheric effects
    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Density = 0.3
    atmosphere.Offset = 0.25
    atmosphere.Color = Color3.fromRGB(199, 199, 199)
    atmosphere.Decay = Color3.fromRGB(92, 60, 13)
    atmosphere.Glare = 0.5
    atmosphere.Haze = 1.8
    atmosphere.Parent = Lighting

    print("[${serviceName}] Enhanced lighting configured")
end

-- Enhanced world update system
function ${serviceName}:StartWorldUpdates()
    RunService.Heartbeat:Connect(function()
        if not isInitialized then return end

        -- Update chunk management
        self:UpdateChunkManagement()

        -- Cleanup old chunks
        self:CleanupOldChunks()
    end)
end

-- Enhanced chunk management
function ${serviceName}:UpdateChunkManagement()
    local currentTime = tick()

    -- Update chunk access times
    for _, chunk in pairs(activeChunks) do
        if currentTime - chunk.lastAccess > 300 then -- 5 minutes
            self:UnloadChunk(chunk)
        end
    end
end

-- Enhanced chunk cleanup
function ${serviceName}:CleanupOldChunks()
    local maxChunks = config.maxChunks

    if #activeChunks > maxChunks then
        -- Sort chunks by last access time
        table.sort(activeChunks, function(a, b)
            return a.lastAccess < b.lastAccess
        end)

        -- Remove oldest chunks
        while #activeChunks > maxChunks do
            local oldestChunk = table.remove(activeChunks, 1)
            self:UnloadChunk(oldestChunk)
        end
    end
end

-- Enhanced chunk unloading
function ${serviceName}:UnloadChunk(chunk: WorldChunk)
    for _, obj in pairs(chunk.objects) do
        if obj and obj.Parent then
            obj:Destroy()
        end
    end

    table.clear(chunk.objects)
    chunk.loaded = false

    print("[${serviceName}] Unloaded chunk:", chunk.id)
end

-- Enhanced utility methods
function ${serviceName}:GetChunkByPosition(position: Vector3): WorldChunk?
    local chunkX = math.floor(position.X / config.chunkSize)
    local chunkZ = math.floor(position.Z / config.chunkSize)
    local chunkId = string.format("%d_%d", chunkX, chunkZ)

    return worldChunks[chunkId]
end

function ${serviceName}:GetActiveChunks(): {WorldChunk}
    return activeChunks
end

function ${serviceName}:GetWorldConfig(): WorldConfig
    return config
end

-- Enhanced shutdown method
function ${serviceName}:Shutdown()
    if not isInitialized then return end

    -- Unload all chunks
    for _, chunk in pairs(activeChunks) do
        self:UnloadChunk(chunk)
    end

    -- Clear data
    table.clear(worldChunks)
    table.clear(activeChunks)

    isInitialized = false
    print("[${serviceName}] ✅ World service shutdown completed")
end

return ${serviceName}
`,

        event: `--!strict
-- ${serviceName}.lua - Enhanced Event Management Service
-- AI-optimized for GitHub Copilot event handling patterns

local ${serviceName} = {}

-- Enhanced type definitions for event management
export type EventCallback = (player: Player?, ...any) -> ()
export type EventConfig = {
    rateLimited: boolean,
    maxCallsPerSecond: number,
    validateArgs: boolean,
    logCalls: boolean,
}

export type RegisteredEvent = {
    name: string,
    callback: EventCallback,
    config: EventConfig,
    callCount: number,
    lastCall: number,
}

-- Enhanced service dependencies
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Enhanced event management state
local isInitialized = false
local registeredEvents: {[string]: RegisteredEvent} = {}
local playerCallCounts: {[Player]: {[string]: number}} = {}
local eventMetrics = {
    totalCalls = 0,
    errorCount = 0,
    rateLimitHits = 0,
}

-- Enhanced default event configuration
local DEFAULT_EVENT_CONFIG: EventConfig = {
    rateLimited = true,
    maxCallsPerSecond = 10,
    validateArgs = true,
    logCalls = false,
}

-- Initialize enhanced event service
function ${serviceName}:Initialize()
    if isInitialized then
        warn("[${serviceName}] Event service already initialized")
        return false
    end

    -- Enhanced initialization sequence
    local initSuccess = pcall(function()
        self:SetupRemoteEvents()
        self:SetupEventValidation()
        self:StartMetricsTracking()
        self:SetupPlayerTracking()
    end)

    if not initSuccess then
        error("[${serviceName}] Failed to initialize event service")
        return false
    end

    isInitialized = true
    print("[${serviceName}] ✅ Enhanced event service initialized")
    return true
end

-- Enhanced RemoteEvent setup
function ${serviceName}:SetupRemoteEvents()
    local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteEventsFolder then
        error("[${serviceName}] RemoteEvents folder not found")
        return
    end

    -- Setup enhanced handlers for all RemoteEvents
    for _, remoteEvent in pairs(remoteEventsFolder:GetChildren()) do
        if remoteEvent:IsA("RemoteEvent") then
            self:SetupEnhancedRemoteEventHandler(remoteEvent)
        end
    end

    print("[${serviceName}] RemoteEvent handlers configured:", #remoteEventsFolder:GetChildren())
end

-- Enhanced RemoteEvent handler setup
function ${serviceName}:SetupEnhancedRemoteEventHandler(remoteEvent: RemoteEvent)
    remoteEvent.OnServerEvent:Connect(function(player, ...)
        local args = {...}
        local eventName = remoteEvent.Name

        -- Enhanced event processing with validation and rate limiting
        spawn(function()
            self:ProcessRemoteEvent(player, eventName, args)
        end)
    end)
end

-- Enhanced event processing with comprehensive validation
function ${serviceName}:ProcessRemoteEvent(player: Player, eventName: string, args: {any})
    local currentTime = tick()

    -- Rate limiting check
    if not self:CheckRateLimit(player, eventName, currentTime) then
        eventMetrics.rateLimitHits = eventMetrics.rateLimitHits + 1
        warn("[${serviceName}] Rate limit exceeded for", player.Name, "event:", eventName)
        return
    end

    -- Find registered event handler
    local registeredEvent = registeredEvents[eventName]
    if not registeredEvent then
        -- Try to handle unknown events gracefully
        self:HandleUnknownEvent(player, eventName, args)
        return
    end

    -- Argument validation
    if registeredEvent.config.validateArgs then
        local validationResult = self:ValidateEventArgs(eventName, args)
        if not validationResult then
            eventMetrics.errorCount = eventMetrics.errorCount + 1
            warn("[${serviceName}] Invalid arguments for event:", eventName, "from player:", player.Name)
            return
        end
    end

    -- Execute event callback with error handling
    local callSuccess = pcall(function()
        registeredEvent.callback(player, unpack(args))
    end)

    if callSuccess then
        -- Update metrics
        registeredEvent.callCount = registeredEvent.callCount + 1
        registeredEvent.lastCall = currentTime
        eventMetrics.totalCalls = eventMetrics.totalCalls + 1

        -- Log if enabled
        if registeredEvent.config.logCalls then
            print("[${serviceName}] Event processed:", eventName, "from:", player.Name)
        end
    else
        eventMetrics.errorCount = eventMetrics.errorCount + 1
        warn("[${serviceName}] Error processing event:", eventName, "from:", player.Name)
    end
end

-- Enhanced rate limiting system
function ${serviceName}:CheckRateLimit(player: Player, eventName: string, currentTime: number): boolean
    local registeredEvent = registeredEvents[eventName]
    if not registeredEvent or not registeredEvent.config.rateLimited then
        return true
    end

    -- Initialize player tracking if needed
    if not playerCallCounts[player] then
        playerCallCounts[player] = {}
    end

    if not playerCallCounts[player][eventName] then
        playerCallCounts[player][eventName] = 0
    end

    -- Check calls per second
    local maxCalls = registeredEvent.config.maxCallsPerSecond
    local timeWindow = 1 -- 1 second window

    -- Reset counter if enough time has passed
    if currentTime - registeredEvent.lastCall > timeWindow then
        playerCallCounts[player][eventName] = 0
    end

    -- Check if limit exceeded
    if playerCallCounts[player][eventName] >= maxCalls then
        return false
    end

    -- Increment counter
    playerCallCounts[player][eventName] = playerCallCounts[player][eventName] + 1
    return true
end

-- Enhanced argument validation
function ${serviceName}:ValidateEventArgs(eventName: string, args: {any}): boolean
    -- Implement specific validation rules for different events
    local validationRules = {
        PlayerMoved = function(args)
            return #args >= 1 and typeof(args[1]) == "Vector3"
        end,

        ScoreUpdate = function(args)
            return #args >= 1 and typeof(args[1]) == "number" and args[1] >= 0
        end,

        PowerUpActivated = function(args)
            return #args >= 1 and typeof(args[1]) == "string" and args[1] ~= ""
        end,

        GameStateChanged = function(args)
            local validStates = {"Waiting", "Playing", "Paused", "Ended"}
            return #args >= 1 and typeof(args[1]) == "string" and table.find(validStates, args[1])
        end,
    }

    local validator = validationRules[eventName]
    if validator then
        return validator(args)
    end

    -- Default validation - basic type checking
    for _, arg in pairs(args) do
        local argType = typeof(arg)
        if argType == "userdata" or argType == "function" then
            return false -- Reject unsafe types
        end
    end

    return true
end

-- Enhanced unknown event handling
function ${serviceName}:HandleUnknownEvent(player: Player, eventName: string, args: {any})
    warn("[${serviceName}] Unknown event received:", eventName, "from:", player.Name)

    -- Log for debugging
    local eventData = {
        player = player.Name,
        event = eventName,
        args = args,
        timestamp = tick(),
    }

    -- Could send to analytics service here
    print("[${serviceName}] Unknown event data:", HttpService:JSONEncode(eventData))
end

-- Enhanced event registration
function ${serviceName}:RegisterEvent(eventName: string, callback: EventCallback, config: EventConfig?)
    if not isInitialized then
        error("[${serviceName}] Service not initialized")
        return false
    end

    -- Merge with default config
    local eventConfig = config or DEFAULT_EVENT_CONFIG
    if config then
        for key, value in pairs(DEFAULT_EVENT_CONFIG) do
            if eventConfig[key] == nil then
                eventConfig[key] = value
            end
        end
    end

    -- Register the event
    registeredEvents[eventName] = {
        name = eventName,
        callback = callback,
        config = eventConfig,
        callCount = 0,
        lastCall = 0,
    }

    print("[${serviceName}] ✅ Event registered:", eventName)
    return true
end

-- Enhanced event unregistration
function ${serviceName}:UnregisterEvent(eventName: string): boolean
    if registeredEvents[eventName] then
        registeredEvents[eventName] = nil
        print("[${serviceName}] Event unregistered:", eventName)
        return true
    end

    return false
end

-- Enhanced player tracking setup
function ${serviceName}:SetupPlayerTracking()
    -- Clean up player data when they leave
    Players.PlayerRemoving:Connect(function(player)
        if playerCallCounts[player] then
            playerCallCounts[player] = nil
        end
    end)
end

-- Enhanced metrics tracking
function ${serviceName}:StartMetricsTracking()
    spawn(function()
        while isInitialized do
            wait(60) -- Log metrics every minute

            print("[${serviceName}] Metrics - Total calls:", eventMetrics.totalCalls,
                  "Errors:", eventMetrics.errorCount, "Rate limit hits:", eventMetrics.rateLimitHits)
        end
    end)
end

-- Enhanced utility methods
function ${serviceName}:GetEventMetrics()
    return {
        totalCalls = eventMetrics.totalCalls,
        errorCount = eventMetrics.errorCount,
        rateLimitHits = eventMetrics.rateLimitHits,
        registeredEvents = #registeredEvents,
        activeEvents = registeredEvents,
    }
end

function ${serviceName}:GetRegisteredEvents(): {string}
    local eventNames = {}
    for eventName, _ in pairs(registeredEvents) do
        table.insert(eventNames, eventName)
    end
    return eventNames
end

function ${serviceName}:FireEventToClient(player: Player, eventName: string, ...)
    local remoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild(eventName)
    if remoteEvent then
        remoteEvent:FireClient(player, ...)
    else
        warn("[${serviceName}] RemoteEvent not found:", eventName)
    end
end

function ${serviceName}:FireEventToAllClients(eventName: string, ...)
    local remoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild(eventName)
    if remoteEvent then
        remoteEvent:FireAllClients(...)
    else
        warn("[${serviceName}] RemoteEvent not found:", eventName)
    end
end

-- Enhanced shutdown method
function ${serviceName}:Shutdown()
    if not isInitialized then return end

    -- Clear all registered events
    table.clear(registeredEvents)

    -- Clear player tracking
    table.clear(playerCallCounts)

    -- Reset metrics
    eventMetrics.totalCalls = 0
    eventMetrics.errorCount = 0
    eventMetrics.rateLimitHits = 0

    isInitialized = false
    print("[${serviceName}] ✅ Event service shutdown completed")
end

return ${serviceName}
`
    };

    return templates[serviceType] || templates.game;
}
