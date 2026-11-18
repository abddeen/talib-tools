# 🌐 ArabicHelper — macOS Menu Bar Screen Translator

**ArabicHelper** is a native macOS menu bar app that lets you capture any section of your screen with a customizable global shortcut, automatically extracts the text using macOS Vision OCR, detects the source language, and translates the content simultaneously into **both Arabic and English** with an instant popup from the menu bar item.

---

## ✨ Features & Functional Requirements

| Requirement | Implementation |
|---|---|
| **Customizable Shortcut** | User can configure any keyboard shortcut (defaults to **`⌘ ⇧ 2`**). Uses the low-overhead Carbon HotKey API (`RegisterEventHotKey`) so it works anywhere across macOS without requiring accessibility permissions. |
| **Section Screenshot** | Invokes macOS interactive selection (`/usr/sbin/screencapture -i`) providing the native crosshair selection tool. |
| **Automatic OCR & Language Detection** | Powered by Apple's **Vision framework** (`VNRecognizeTextRequestRevision3`) with support for Arabic, English, and 30+ languages. Automatic language identification via **NaturalLanguage framework** and Unicode script analysis. |
| **Dual Translation (Arabic & English)** | Automatically identifies source text: <br>• If source is **Arabic**, displays original Arabic and translates to **English**.<br>• If source is **English**, displays original English and translates to **Arabic**.<br>• If source is **any other language** (French, German, Spanish, etc.), concurrently translates to **both Arabic and English**! |
| **Menu Bar Item & Popup** | Runs as a background accessory app (`LSUIElement = true`). Upon capture, automatically pops open a SwiftUI interface displaying both translations, RTL Arabic typography, one-click copy, audio pronunciation, and capture history. |

---

## 🚀 Quick Start

### 1. Build the App
```bash
./build.sh
```
Or with Make:
```bash
make
```

### 2. Launch
```bash
./build.sh run
```
Or double-click `build/ArabicHelper.app` in Finder.

### 3. (Optional) Install to Applications
```bash
./build.sh install
```

---

## 🖥️ How to Use

1. **Launch ArabicHelper**: The app appears in your macOS top menu bar as `ع/A` (or book icon).
2. **Press Shortcut**: Press **`⌘ + ⇧ + 2`** (or your custom shortcut).
3. **Select Screen Area**: Drag the crosshairs over any text on screen (image, PDF, website, chat, video subtitle).
4. **Instant Dual Translation**: The menu bar popover drops down automatically showing:
   - **Original Text** with detected language badge (e.g. `🌐 Detected: English`) and screenshot thumbnail.
   - **Arabic Translation (العربية)** in clean RTL font with a **Copy** button and **Listen** audio button.
   - **English Translation** with a **Copy** button and **Listen** audio button.
5. **Change Shortcut**: Click the **Settings** tab in the popup to record any new shortcut combination (e.g. `⌃ ⌥ A`, `⌘ ⇧ 4`, etc.).

---

## 📁 Project Architecture

```
arabic-helper/
├── build.sh                               // Build & packaging script (creates .app bundle)
├── Makefile                               // Convenience make targets (build, run, install, clean)
├── Package.swift                          // Swift Package Manager configuration
├── Sources/
│   └── ArabicHelper/
│       ├── Main.swift                     // NSApplication & AppDelegate setup (LSUIElement)
│       ├── AppState.swift                 // Central observable application coordinator
│       ├── Models/
│       │   ├── ShortcutModel.swift        // KeyCode & modifier abstraction with Carbon mapping
│       │   ├── TranslationResult.swift    // Model holding capture, OCR, and dual translations
│       │   └── UserPreferences.swift      // User settings (shortcut, auto-open, auto-copy)
│       ├── Services/
│       │   ├── HotKeyManager.swift        // Carbon global shortcut listener
│       │   ├── ScreenCaptureService.swift // Interactive screen selection (/usr/sbin/screencapture)
│       │   ├── OCRService.swift           // Vision VNRecognizeTextRequest & NaturalLanguage
│       │   ├── TranslationService.swift   // Language detection & dual translation engine
│       │   └── SpeechService.swift        // Text-to-speech for Arabic (ar-SA) and English (en-US)
│       ├── UI/
│       │   ├── StatusBarController.swift  // NSStatusItem and NSPopover coordinator
│       │   ├── PopupView.swift            // Main popover view with Translate, History, & Settings
│       │   ├── TranslationCardView.swift  // Card component with RTL support, copy, & audio
│       │   ├── HistoryView.swift          // Past captures & translations list
│       │   ├── SettingsView.swift         // Settings & preferences tab
│       │   └── ShortcutRecorderView.swift // Interactive keyboard shortcut recorder
│       └── Resources/
│           └── Info.plist                 // Application metadata (LSUIElement = true)
```

---

## ⚙️ Requirements
- macOS 14.0 Sonoma or later
- Apple Silicon (M1/M2/M3/M4) or Intel Mac
- Standard macOS CommandLineTools (`swiftc`)
