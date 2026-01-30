// LLMProvider - LLM Module
// Copyright 2026

import Foundation

public enum LLMProvider: String, CaseIterable, Sendable {
    case onDevice = "on_device"
    case mlx = "mlx"
    case anthropic = "anthropic"

    public var displayName: String {
        switch self {
        case .onDevice: return "On-Device (Apple)"
        case .mlx: return "MLX (Local)"
        case .anthropic: return "Claude (Anthropic)"
        }
    }

    public var description: String {
        switch self {
        case .onDevice: return "Uses Apple's Foundation Models. Free, private, requires iOS 26+."
        case .mlx: return "Uses MLX models on Apple Silicon. Free, private, downloads model once."
        case .anthropic: return "Uses Claude API. Requires API key, best quality."
        }
    }

    public var requiresAPIKey: Bool {
        self == .anthropic
    }

    /// Providers available on current platform
    public static var availableOnCurrentPlatform: [LLMProvider] {
        // MLX works on both macOS and iOS with Apple Silicon
        return allCases
    }
}
