import SwiftUI
import LLM

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var settings = SettingsService.shared
    @State private var apiKeyInput: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("AI Provider", selection: $settings.provider) {
                        ForEach(LLMProvider.availableOnCurrentPlatform, id: \.self) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }

                    Text(settings.provider.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("AI Model")
                }

                if settings.provider == .mlx {
                    Section {
                        Picker("Model", selection: $settings.mlxModelId) {
                            ForEach(MLXModelOption.available) { model in
                                VStack(alignment: .leading) {
                                    Text(model.displayName)
                                    Text("\(model.size) - \(model.description)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .tag(model.id)
                            }
                        }
                        #if os(macOS)
                        .pickerStyle(.inline)
                        #endif

                        // Info about download
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                            Text("Model will download on first use (~\(settings.selectedMLXModel?.size ?? ""))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("MLX Model")
                    } footer: {
                        Text("MLX models run locally on Apple Silicon. Models are downloaded once and cached.")
                    }
                }

                if settings.provider == .anthropic {
                    Section {
                        SecureField("API Key", text: $apiKeyInput)
                            .textContentType(.password)
                            .autocorrectionDisabled()
                            #if os(iOS)
                            .textInputAutocapitalization(.never)
                            #endif
                            .onAppear {
                                apiKeyInput = settings.anthropicAPIKey
                            }
                            .onChange(of: apiKeyInput) { _, newValue in
                                settings.anthropicAPIKey = newValue
                            }

                        if settings.isAnthropicConfigured {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("API key configured")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Link(destination: URL(string: "https://console.anthropic.com/settings/keys")!) {
                            HStack {
                                Text("Get API Key")
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                            }
                        }
                    } header: {
                        Text("Anthropic API")
                    } footer: {
                        Text("Your API key is stored locally on your device.")
                    }
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
