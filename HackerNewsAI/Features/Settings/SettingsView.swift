import SwiftUI

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
                        .pickerStyle(.inline)

                        if let selected = settings.selectedMLXModel {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(.secondary)
                                Text("Model will be downloaded on first use (~\(selected.size))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text("MLX Model")
                    } footer: {
                        Text("MLX models run locally on Apple Silicon. The model is downloaded once and cached.")
                    }
                }

                if settings.provider == .anthropic {
                    Section {
                        SecureField("API Key", text: $apiKeyInput)
                            .textContentType(.password)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
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
