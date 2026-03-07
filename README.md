# Analyst by Potomac

**Your AI-powered trading assistant — natively built for every Apple platform.**

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-100%25-blue.svg)](https://developer.apple.com/swiftui/)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20|%20iPad%20|%20Mac%20|%20Watch%20|%20Vision%20|%20CarPlay-lightgrey.svg)](https://developer.apple.com)

---

## Overview

Analyst is a premium financial AI assistant that brings Claude-powered analysis, AFL code generation, knowledge base management, and real-time market data to your fingertips — across iPhone, iPad, Mac, Apple Watch, Apple Vision Pro, and CarPlay.

### Key Features

- 💬 **AI Chat** — Stream conversations with Claude AI, complete with tool calling and generative UI cards
- 📊 **Generative UI** — Rich stock cards, charts, weather, news, AFL code views rendered natively in SwiftUI
- ⚡ **AFL Generator** — Generate, optimize, debug, validate, and explain AmiBroker Formula Language code
- 🔬 **Strategy Reverse Engineering** — Deconstruct trading strategies with AI-guided research and Mermaid diagrams
- 🧠 **Knowledge Base** — Upload documents (PDF, CSV, TXT) and query them with semantic search
- 📈 **Backtesting** — Upload and analyze backtest results with AI-powered recommendations
- 🔍 **Company Research** — Deep-dive research with technicals, news, and filings
- 🎤 **Voice Mode** — Hands-free conversation with speech recognition and natural TTS
- 🎨 **Presentations** — Generate PowerPoint presentations via AI skills
- 🛡️ **Security** — Biometric auth (Face ID / Touch ID), auto-lock, and encrypted keychain storage

---

## Platforms

| Platform | Status | Min Version |
|----------|--------|-------------|
| 📱 iPhone | ✅ Full | iOS 17 |
| 📱 iPad | ✅ Full | iPadOS 17 |
| 💻 Mac | ✅ Full | macOS 14 |
| ⌚ Apple Watch | ✅ Compact Chat | watchOS 10 |
| 🥽 Vision Pro | ✅ Full | visionOS 1 |
| 🚗 CarPlay | ✅ Quick Chat + Markets | iOS 17 |

---

## Architecture

```
AnalystApp/
├── Sources/Analyst/
│   ├── AnalystApp.swift              # @main entry — adaptive per platform
│   ├── Core/
│   │   ├── Constants/APIEndpoints.swift   # All 80+ API routes
│   │   └── Utilities/                     # Haptics, Clipboard, Voice, Biometrics, Network
│   ├── Models/
│   │   ├── APIModels.swift           # 20+ response types (Skills, Files, Reverse Eng, etc.)
│   │   ├── Auth/User.swift           # User, AuthResponse, LoginRequest
│   │   └── Chat/                     # Message, Conversation, StreamEvent, ToolCall, AnyCodable
│   ├── Services/
│   │   ├── Network/
│   │   │   ├── APIClient.swift       # Core actor-based HTTP client with JWT auth
│   │   │   └── APIClient+Extensions.swift  # 50+ additional API methods
│   │   ├── Streaming/SSEClient.swift # Vercel AI SDK Data Stream Protocol parser
│   │   ├── Cache/CacheManager.swift
│   │   └── Persistence/PersistenceManager.swift
│   ├── ViewModels/                   # @Observable ViewModels (Chat, Auth, AFL, Backtest, etc.)
│   ├── Views/
│   │   ├── Chat/                     # ChatView, VoiceConversation, FileAttachment
│   │   ├── AFL/                      # AFL Generator, Detail, Features
│   │   ├── GenerativeUI/            # Stock cards, charts, weather, news, AFL code views
│   │   ├── Knowledge/               # Document browser, upload, search
│   │   ├── Backtest/                # Backtest viewer, metrics grid
│   │   ├── Research/                # Company researcher
│   │   ├── Presentations/           # Presentation builder
│   │   ├── Dashboard/               # Home dashboard
│   │   ├── Settings/                # Settings, security, privacy
│   │   ├── Auth/                    # Login, register, forgot password, app lock
│   │   ├── Watch/                   # watchOS compact chat interface
│   │   ├── CarPlay/                 # CarPlay scene delegate
│   │   ├── Root/MainTabView.swift   # Main navigation
│   │   └── Shared/                  # Reusable components, modifiers
│   └── Theme/                       # Colors, Typography, Spacing, AppTheme
```

---

## Tech Stack

- **Language:** Swift 6.0 with strict concurrency
- **UI:** 100% SwiftUI — no UIKit views
- **State:** `@Observable` (Observation framework) + `@Environment`
- **Networking:** Actor-based `APIClient` with `async/await`
- **Streaming:** Custom SSE parser for Vercel AI SDK Data Stream Protocol
- **Auth:** JWT Bearer tokens stored in encrypted Keychain
- **Concurrency:** Swift structured concurrency with `Task`, `AsyncThrowingStream`

---

## API Integration

Fully integrated with the **Analyst by Potomac** backend API (v1.4.0):

| Category | Endpoints | Status |
|----------|-----------|--------|
| Auth | Login, Register, Profile, API Keys, Password | ✅ |
| Chat | Conversations, Messages, Stream, Upload, TTS | ✅ |
| AFL | Generate, Optimize, Debug, Explain, Validate, Presets | ✅ |
| Reverse Engineering | Start, Continue, Research, Schematic, Code Gen | ✅ |
| Skills | List, Execute, Stream, Jobs, Multi | ✅ |
| Knowledge Base | Upload, Search, Documents, Stats | ✅ |
| Backtest | Upload, Analyze, CRUD | ✅ |
| Research | Company, News, History | ✅ |
| Presentations | Generate PPTX, Templates | ✅ |
| Stock Data | Ticker, Historical, Options (yfinance) | ✅ |
| Files | Download, Info, Generated | ✅ |
| Content | Articles CRUD | ✅ |
| Health | Server status | ✅ |

---

## Getting Started

### Prerequisites

- Xcode 16+ (for Swift 6.0 and iOS 17 SDK)
- macOS 14 Sonoma or later
- Apple Developer account (for device testing)

### Build & Run

```bash
# Clone the repo
git clone https://github.com/sohaibali73/-Analyst-iOS-.git
cd -Analyst-iOS-

# Open in Xcode
open Analyst.xcodeproj
```

1. Select your target device (iPhone, iPad, Mac, Watch, etc.)
2. Build and run (⌘+R)
3. Register or login with your Analyst by Potomac account

### API Configuration

The app connects to `https://analystbypotomac.vercel.app` by default. To use a local backend:

1. Open `APIEndpoints.swift`
2. Change `baseURL` to `http://localhost:8000`

---

## Design System

### Typography
- **Rajdhani** — Headers, titles, tracking labels
- **Quicksand** — Body text, UI elements
- **Fira Code** — Code blocks, AFL display

### Colors
- **Potomac Yellow** `#FEC00F` — Primary accent
- **Potomac Turquoise** `#00DED1` — Secondary accent
- **Dark Theme** — Designed for `#0A0A0A` to `#0D0D0D` backgrounds

---

## License

© 2024-2026 Potomac. All rights reserved.

---

## Support

- **GitHub:** [sohaibali73/Potomac-Analyst-Workbench](https://github.com/sohaibali73/Potomac-Analyst-Workbench)
- **API Docs:** [analystbypotomac.vercel.app/docs](https://analystbypotomac.vercel.app/docs)
