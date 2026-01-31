<p align="center">
  <img src="AppIcon.png" width="128" height="128" alt="HackerNewsAI App Icon">
</p>

<h1 align="center">HackerNewsAI</h1>

<p align="center">
  <strong>AI-powered Hacker News reader for iOS and macOS</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%2018%2B%20%7C%20macOS%2015%2B-blue" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-6.0-orange" alt="Swift">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
</p>

---

## Features

- **AI Catch-Up Summaries** — Get a personalized summary of what you missed since your last visit
- **Multiple LLM Backends** — Choose between on-device Apple Intelligence, local MLX models, or Claude API
- **Native SwiftUI** — Built entirely with SwiftUI for iOS and macOS
- **Threaded Comments** — Browse comment threads with collapsible replies
- **Privacy-First** — On-device options mean your reading habits stay private

## LLM Providers

| Provider | Description | Requirements |
|----------|-------------|--------------|
| **On-Device (Apple)** | Uses Apple Foundation Models | iOS 26+ / macOS 26+ |
| **MLX (Local)** | Runs Qwen3 or Llama models locally | Apple Silicon, ~400MB-2.5GB download |
| **Claude (Anthropic)** | Cloud API with best quality | API key required |

## Requirements

- iOS 18.0+ / macOS 15.0+
- Xcode 16.0+
- Swift 6.0+

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/n0an/HackerNewsAI.git
   ```

2. Open `HackerNewsAI.xcodeproj` in Xcode

3. Build and run on your device or simulator

## Architecture

The app follows MVVM architecture with feature-based organization:

- **Core** — Models, Services, and Extensions
- **Features** — Feed, Comments, Summary, Settings
- **Modules/LLM** — Swift Package abstracting LLM providers

## License

MIT License
