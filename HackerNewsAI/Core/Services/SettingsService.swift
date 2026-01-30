import Foundation

enum LLMProvider: String, CaseIterable {
    case onDevice = "on_device"
    case mlx = "mlx"
    case anthropic = "anthropic"

    var displayName: String {
        switch self {
        case .onDevice: return "On-Device (Apple)"
        case .mlx: return "MLX (Local)"
        case .anthropic: return "Claude (Anthropic)"
        }
    }

    var description: String {
        switch self {
        case .onDevice: return "Uses Apple's Foundation Models. Free, private, requires iOS 26+."
        case .mlx: return "Uses MLX models on Apple Silicon. Free, private, downloads model once."
        case .anthropic: return "Uses Claude API. Requires API key, best quality."
        }
    }

    var requiresAPIKey: Bool {
        self == .anthropic
    }

    /// Providers available on current platform
    static var availableOnCurrentPlatform: [LLMProvider] {
        #if os(macOS)
        return allCases
        #else
        return allCases.filter { $0 != .mlx }
        #endif
    }
}

struct MLXModelOption: Identifiable {
    let id: String
    let displayName: String
    let size: String
    let description: String

    static let available: [MLXModelOption] = [
        MLXModelOption(
            id: "mlx-community/Qwen3-0.6B-4bit",
            displayName: "Qwen3 0.6B",
            size: "~400MB",
            description: "Fastest, minimal memory"
        ),
        MLXModelOption(
            id: "mlx-community/Qwen3-4B-4bit",
            displayName: "Qwen3 4B",
            size: "~2.5GB",
            description: "Best balance of speed and quality"
        ),
        MLXModelOption(
            id: "mlx-community/Llama-3.2-3B-Instruct-4bit",
            displayName: "Llama 3.2 3B",
            size: "~2GB",
            description: "Good quality, moderate size"
        ),
    ]
}

@Observable
class SettingsService {
    static let shared = SettingsService()

    private let providerKey = "llm_provider"
    private let apiKeyKey = "anthropic_api_key"
    private let mlxModelKey = "mlx_model_id"
    private let defaults = UserDefaults.standard

    var provider: LLMProvider {
        didSet {
            defaults.set(provider.rawValue, forKey: providerKey)
        }
    }

    var anthropicAPIKey: String {
        didSet {
            defaults.set(anthropicAPIKey, forKey: apiKeyKey)
        }
    }

    var mlxModelId: String {
        didSet {
            defaults.set(mlxModelId, forKey: mlxModelKey)
        }
    }

    var isAnthropicConfigured: Bool {
        !anthropicAPIKey.isEmpty
    }

    var selectedMLXModel: MLXModelOption? {
        MLXModelOption.available.first { $0.id == mlxModelId }
    }

    private init() {
        let savedProvider = defaults.string(forKey: providerKey) ?? LLMProvider.onDevice.rawValue
        self.provider = LLMProvider(rawValue: savedProvider) ?? .onDevice
        self.anthropicAPIKey = defaults.string(forKey: apiKeyKey) ?? ""
        self.mlxModelId = defaults.string(forKey: mlxModelKey) ?? "mlx-community/Qwen3-0.6B-4bit"
    }
}
