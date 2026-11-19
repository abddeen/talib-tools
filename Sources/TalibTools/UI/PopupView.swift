import SwiftUI
import AppKit

public struct PopupView: View {
    @EnvironmentObject var appState: AppState
    @State private var enteredText: String = ""
    
    // Lexicon dictionary state
    @State private var dictionaryResults: [DictionaryWord] = []
    @State private var dictionarySearchedWord: String? = nil
    @State private var isDictionaryLoading = false
    @State private var dictionaryError: String? = nil
    @State private var showingAllDictionaryResults = false
    @State private var expandedDictionaryEntryID: String? = nil
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top App Bar
            headerBar
            
            Divider()
            
            // Body Content based on active tab
            Group {
                switch appState.activeTab {
                case .translation:
                    translationContentView
                case .history:
                    HistoryView()
                        .environmentObject(appState)
                case .settings:
                    SettingsView()
                        .environmentObject(appState)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Divider()
            
            // Bottom Status & Quick Action Bar
            bottomBar
        }
        .frame(width: 440, height: 580)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Header App Icon
    private var headerAppIconView: some View {
        Group {
            if let icon = NSImage(named: "AppIcon") {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 26, height: 26)
                    .cornerRadius(5)
            } else {
                // Fallback when running outside the .app bundle
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color.accentColor)
                        .frame(width: 26, height: 26)
                    Image(systemName: "character.book.closed.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(spacing: 12) {
            // App Branding
            HStack(spacing: 7) {
                headerAppIconView
                
                Text("TalibTools")
                    .font(.system(size: 13, weight: .bold))
            }
            
            Spacer()
            
            // Tab Picker
            Picker("", selection: $appState.activeTab) {
                ForEach(AppTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 210)
            
            // Quit Button
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Quit TalibTools")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
    
    // MARK: - Translation View
    private var translationContentView: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Direct Text Input Card (Always accessible)
                textInputCard
                
                if appState.isProcessing || appState.isCapturing {
                    processingView
                } else if let error = appState.errorMessage {
                    errorCardView(message: error)
                }
                
                if let result = appState.currentResult {
                    // Original Source Card
                    originalSourceCard(result: result)
                }
                
                // Translation Detail Tab Bar: Translation, Vocab, Lexicon
                translationTabPicker
                
                // Content based on active translation tab
                Group {
                    switch appState.activeTranslationTab {
                    case .translation:
                        translationTabContent
                    case .vocab:
                        vocabTabContent
                    case .lexicon:
                        lexiconTabContent
                    }
                }
            }
            .padding(14)
        }
    }
    
    // MARK: - Translation Detail Tab Picker
    private var translationTabPicker: some View {
        Picker("", selection: $appState.activeTranslationTab) {
            ForEach(TranslationTab.allCases) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.vertical, 2)
    }
    
    // MARK: - Translation Tab Content
    @ViewBuilder
    private var translationTabContent: some View {
        if let result = appState.currentResult {
            // Arabic Translation Card
            TranslationCardView(
                title: "العربية (Arabic)",
                badge: "🇦🇪",
                text: result.arabicTranslation,
                isArabic: true,
                languageCode: "ar"
            )
            
            // English Translation Card
            TranslationCardView(
                title: "English",
                badge: "🇬🇧",
                text: result.englishTranslation,
                isArabic: false,
                languageCode: "en"
            )
        } else if !appState.isProcessing && !appState.isCapturing && appState.errorMessage == nil {
            emptyWelcomeState
        }
    }
    
    // MARK: - Vocab Tab Content
    private var vocabTabContent: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 24)
            
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.12))
                    .frame(width: 60, height: 60)
                Image(systemName: "character.book.closed.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.purple)
            }
            
            VStack(spacing: 6) {
                Text("Coming soon")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Vocabulary list, flashcards, and review tools for your translations will be available here.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            Spacer(minLength: 24)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Lexicon Tab Content
    private var detectedSingleArabicWord: String? {
        if let resultWord = appState.currentResult?.singleArabicWord {
            return resultWord
        }
        if appState.currentResult == nil {
            return TranslationResult.extractSingleArabicWord(from: enteredText)
        }
        return nil
    }
    
    @ViewBuilder
    private var lexiconTabContent: some View {
        if let arabicWord = detectedSingleArabicWord {
            // Option to Search the Lexicon for single Arabic word
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.accentColor)
                        Text("Lexicon")
                            .font(.system(size: 13, weight: .bold))
                    }
                    
                    Spacer()
                    
                    Text("Single Arabic Word")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundColor(.accentColor)
                        .cornerRadius(4)
                }
                
                // Word Display Box
                VStack(spacing: 6) {
                    Text(arabicWord)
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .textSelection(.enabled)
                    
                    Text("Ready for dictionary root & definition lookup")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.textBackgroundColor).opacity(0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.18), lineWidth: 1)
                )
                
                // Search Lexicon Button
                Button(action: {
                    Task {
                        await searchDictionary(for: arabicWord)
                    }
                }) {
                    HStack(spacing: 6) {
                        if isDictionaryLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 12, height: 12)
                        } else {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 12, weight: .bold))
                        }
                        Text(isDictionaryLoading ? "Searching..." : "Search the Lexicon")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isDictionaryLoading ? Color.accentColor.opacity(0.6) : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(isDictionaryLoading)
                
                dictionaryResultsView(for: arabicWord)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .onChange(of: arabicWord) { _, _ in
                dictionaryResults = []
                dictionarySearchedWord = nil
                dictionaryError = nil
                showingAllDictionaryResults = false
                expandedDictionaryEntryID = nil
            }
        } else if appState.currentResult != nil {
            // Translation result exists, but neither original nor translated is a single Arabic word
            VStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text("Lexicon")
                        .font(.system(size: 13, weight: .bold))
                    Spacer()
                }
                
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 16))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Single Arabic Word Required")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("Lexicon search is only available when the translated or original text is a single Arabic word.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.1))
                )
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        } else {
            // No translation result yet and no entered Arabic word
            VStack(spacing: 14) {
                Spacer(minLength: 24)
                
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 60, height: 60)
                    Image(systemName: "book.closed")
                        .font(.system(size: 26))
                        .foregroundColor(.accentColor)
                }
                
                VStack(spacing: 6) {
                    Text("Lexicon")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Translate or enter a single Arabic word to search the Lexicon.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                Spacer(minLength: 24)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Lexicon Search
    
    private func searchDictionary(for word: String) async {
        isDictionaryLoading = true
        dictionaryError = nil
        dictionaryResults = []
        showingAllDictionaryResults = false
        expandedDictionaryEntryID = nil
        appState.statusMessage = "Looking up \"\(word)\"..."
        
        do {
            let response = try await DictionaryService.shared.search(word: word)
            dictionaryResults = response.sortedWords
            dictionarySearchedWord = word
            isDictionaryLoading = false
            if response.words.isEmpty {
                appState.statusMessage = "No dictionary entries for \"\(word)\""
            } else {
                appState.statusMessage = "Found \(response.words.count) dictionary entries"
            }
        } catch {
            dictionaryError = error.localizedDescription
            dictionarySearchedWord = word
            isDictionaryLoading = false
            appState.statusMessage = "Dictionary lookup failed"
        }
    }
    
    private var visibleDictionaryEntries: [DictionaryWord] {
        showingAllDictionaryResults ? dictionaryResults : Array(dictionaryResults.prefix(6))
    }
    
    @ViewBuilder
    private func dictionaryResultsView(for word: String) -> some View {
        if isDictionaryLoading {
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Looking up \"\(word)\"...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(8)
        } else if let error = dictionaryError {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                Text(error)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.orange.opacity(0.1))
            )
        } else if dictionarySearchedWord == word && dictionaryResults.isEmpty {
            HStack(spacing: 8) {
                Image(systemName: "book.closed")
                    .foregroundColor(.secondary)
                    .font(.caption)
                Text("No dictionary entries found for \"\(word)\".")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.08))
            )
        } else if dictionarySearchedWord == word {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(dictionaryResults.count) entries")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Spacer()
                    if dictionaryResults.count > 6 {
                        Button(action: {
                            withAnimation {
                                showingAllDictionaryResults.toggle()
                            }
                        }) {
                            Text(showingAllDictionaryResults ? "Show fewer" : "Show all \(dictionaryResults.count)")
                                .font(.caption2)
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                ForEach(visibleDictionaryEntries) { entry in
                    dictionaryEntryCard(entry)
                }
            }
        }
    }
    
    private func dictionaryEntryCard(_ entry: DictionaryWord) -> some View {
        let isExpanded = expandedDictionaryEntryID == entry.id
        
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(entry.text)
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .textSelection(.enabled)
                
                Spacer()
                
                if !entry.form.isEmpty {
                    Text("Form \(entry.form)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.12))
                        .foregroundColor(.accentColor)
                        .cornerRadius(4)
                }
                
                Button(action: {
                    appState.copyToPasteboard(entry.plainFullDefinition)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Copy full definition")
            }
            
            if !entry.transliteration.isEmpty {
                Text("/\(entry.transliteration)/")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !entry.root.text.isEmpty {
                HStack(spacing: 5) {
                    Text("Root:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(entry.root.text)
                        .font(.system(size: 13, design: .serif))
                        .textSelection(.enabled)
                    if entry.root.wordCount > 0 {
                        Text("(\(entry.root.wordCount) words, \(entry.root.formCount) forms)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if !entry.plural.text.isEmpty {
                HStack(spacing: 5) {
                    Text("Plural:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(entry.plural.text)
                        .font(.system(size: 12, design: .serif))
                        .textSelection(.enabled)
                    if !entry.plural.transliteration.isEmpty {
                        Text("/\(entry.plural.transliteration)/")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if !entry.plainShortDefinition.isEmpty {
                Text(entry.plainShortDefinition)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
            }
            
            if !entry.plainFullDefinition.isEmpty {
                Text(entry.plainFullDefinition)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(isExpanded ? nil : 3)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(action: {
                    withAnimation {
                        expandedDictionaryEntryID = isExpanded ? nil : entry.id
                    }
                }) {
                    Text(isExpanded ? "Show less" : "Show full definition")
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.textBackgroundColor).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Direct Text Input Card
    private var textInputCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 12))
                        .foregroundColor(.accentColor)
                    Text("Enter Text or Screenshot")
                        .font(.system(size: 12, weight: .bold))
                }
                
                Spacer()
                
                if !enteredText.isEmpty {
                    Button(action: {
                        enteredText = ""
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                            Text("Clear")
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                Button(action: {
                    if let clipboard = NSPasteboard.general.string(forType: .string) {
                        enteredText = clipboard
                    }
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 10))
                        Text("Paste")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Paste from clipboard")
            }
            
            ZStack(alignment: .topLeading) {
                if enteredText.isEmpty {
                    Text("Type or paste text here to translate...")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $enteredText)
                    .font(.system(size: 13))
                    .frame(minHeight: 48, maxHeight: 80)
                    .scrollContentBackground(.hidden)
                    .padding(4)
            }
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(NSColor.textBackgroundColor).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            
            HStack {
                Button(action: {
                    appState.triggerCapture()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "camera")
                            .font(.system(size: 11))
                        Text("Screenshot (\(appState.preferences.shortcut.displayString))")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(5)
                }
                .buttonStyle(.plain)
                .help("Capture a section of your screen")
                
                Spacer()
                
                Button(action: {
                    submitEnteredText()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.caption)
                        Text("Translate")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(enteredText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.25) : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(5)
                }
                .buttonStyle(.plain)
                .disabled(enteredText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || appState.isProcessing)
                .keyboardShortcut(.return, modifiers: [.command])
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.18), lineWidth: 1)
        )
    }
    
    private func submitEnteredText() {
        let text = enteredText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        Task {
            await appState.translateDirectText(text)
        }
    }
    
    // MARK: - Processing View
    private var processingView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
            Text(appState.statusMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor.opacity(0.1))
        )
    }
    
    // MARK: - Error Card
    private func errorCardView(message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Notice")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
        )
    }
    
    // MARK: - Original Source Card
    private func originalSourceCard(result: TranslationResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: result.image != nil ? "camera.viewfinder" : "keyboard")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(result.image != nil ? "Screenshot Source" : "Entered Text")
                        .font(.system(size: 12, weight: .bold))
                }
                
                Spacer()
                
                // Detected Language Badge
                Text("Detected: \(result.detectedLanguageName)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundColor(.accentColor)
                    .cornerRadius(4)
                
                // Copy button for original
                Button(action: {
                    appState.copyToPasteboard(result.originalText)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Copy original text")
            }
            
            HStack(alignment: .top, spacing: 10) {
                // Screenshot Thumbnail (if present)
                if let image = result.image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 80, maxHeight: 60)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.accentColor.opacity(0.1))
                            .frame(width: 32, height: 32)
                        Image(systemName: "text.alignleft")
                            .font(.system(size: 14))
                            .foregroundColor(.accentColor)
                    }
                }
                
                Text(result.originalText)
                    .font(.system(size: 13))
                    .lineLimit(4)
                    .textSelection(.enabled)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(NSColor.textBackgroundColor).opacity(0.5))
            )
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Empty Welcome State
    private var emptyWelcomeState: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 20)
            
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 64, height: 64)
                Image(systemName: "translate")
                    .font(.system(size: 30))
                    .foregroundColor(.accentColor)
            }
            
            VStack(spacing: 4) {
                Text("Ready to Translate")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("Type text in the box above, or press \(appState.preferences.shortcut.displayString) to screenshot any screen section.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            Spacer(minLength: 20)
        }
    }
    
    // MARK: - Bottom Bar
    private var bottomBar: some View {
        HStack {
            Text(appState.statusMessage)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: {
                appState.triggerCapture()
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "camera.fill")
                        .font(.caption)
                    Text("Capture")
                        .font(.caption)
                        .fontWeight(.medium)
                    Text(appState.preferences.shortcut.displayString)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(3)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.12))
                .foregroundColor(.accentColor)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .disabled(appState.isCapturing || appState.isProcessing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
    }
}
