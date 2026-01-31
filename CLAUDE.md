# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HackerNewsAI is a SwiftUI iOS/macOS app that displays Hacker News stories and provides AI-powered "catch up" summaries using multiple LLM backends.

## Build Commands

```bash
# Build the project (Xcode command line)
xcodebuild -project HackerNewsAI.xcodeproj -scheme HackerNewsAI build

# Build the LLM Swift Package (from within the module directory)
cd HackerNewsAI/Modules/LLM && swift build

# Run LLM module tests
cd HackerNewsAI/Modules/LLM && swift test
```

The project is primarily developed in Xcode. Open `HackerNewsAI.xcodeproj` to build and run.

## Architecture

### App Structure

```
HackerNewsAI/
├── HackerNewsAIApp.swift    # App entry point
├── ContentView.swift         # Root view (hosts FeedView)
├── Core/
│   ├── Models/              # Data models (HNStory, HNComment, CommentNode, CatchUpSummary)
│   ├── Services/            # Business logic services
│   └── Extensions/          # Swift extensions
├── Features/
│   ├── Feed/                # Story list (FeedView, FeedViewModel, PostRowView)
│   ├── Comments/            # Comment thread (CommentsView, CommentsViewModel)
│   ├── Summary/             # AI catch-up feature (SummaryView, SummaryViewModel)
│   └── Settings/            # LLM provider configuration
└── Modules/
    └── LLM/                 # Swift Package for LLM abstraction
```

### LLM Module (Swift Package)

Located at `HackerNewsAI/Modules/LLM/`. This is a local Swift Package that abstracts LLM providers:

- **LLMProvider**: Enum defining available providers (onDevice, mlx, anthropic)
- **LLMConfiguration**: Settings for LLM generation
- **LLMGenerationService**: Actor that handles generation across providers
- **MLXModelOption**: Available MLX model configurations

Supports three LLM backends:
1. **On-Device (Apple Foundation Models)** - iOS 26+/macOS 26+ only
2. **MLX** - Local models on Apple Silicon (Qwen3, Llama 3.2)
3. **Anthropic Claude** - Cloud API, requires API key

### Key Services

- **HackerNewsService** (`actor`): Fetches stories and comments from HN Firebase API
- **SummaryService** (`actor`): Orchestrates catch-up summary generation
- **LastVisitService** (`actor`): Tracks user's last visit timestamp via UserDefaults
- **SettingsService** (`@Observable`): Manages LLM provider settings

### Data Flow

1. `FeedView` loads stories via `FeedViewModel` → `HackerNewsService`
2. User taps AI button → `SummaryView` presented
3. `SummaryViewModel` → `SummaryService` → fetches stories since last visit
4. `SummaryService` → `LLMGenerationService.generate()` with configured provider
5. Summary displayed; user can "Mark as Read" to update `LastVisitService`

## Key Patterns

- ViewModels use `@Observable` macro with `@MainActor`
- Services use Swift actors for thread safety
- MVVM architecture with feature-based folder structure
- LLM module re-exports dependencies (`@_exported import`)
