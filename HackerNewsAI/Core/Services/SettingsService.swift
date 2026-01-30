import Foundation

enum LLMProvider: String, CaseIterable {
    case onDevice = "on_device"
    case anthropic = "anthropic"

    var displayName: String {
        switch self {
        case .onDevice: return "On-Device (Free)"
        case .anthropic: return "Claude (Anthropic)"
        }
    }

    var description: String {
        switch self {
        case .onDevice: return "Uses Apple's on-device model. Free, private, works offline."
        case .anthropic: return "Uses Claude API. Requires API key, better quality."
        }
    }
}

@Observable
class SettingsService {
    static let shared = SettingsService()

    private let providerKey = "llm_provider"
    private let apiKeyKey = "anthropic_api_key"
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

    var isAnthropicConfigured: Bool {
        !anthropicAPIKey.isEmpty
    }

    private init() {
        let savedProvider = defaults.string(forKey: providerKey) ?? LLMProvider.onDevice.rawValue
        self.provider = LLMProvider(rawValue: savedProvider) ?? .onDevice
        self.anthropicAPIKey = defaults.string(forKey: apiKeyKey) ?? ""
    }
}
