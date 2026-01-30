//
//  ContentView.swift
//  HackerNewsAI
//
//  Created by Anton Novoselov on 30.01.2026.
//

import SwiftUI
import LLM

struct ContentView: View {
    @State private var joke = ""
    @State private var isLoading = false

    private let model = SystemLanguageModel.default
    private var session: LanguageModelSession { LanguageModelSession(model: model) }

    var body: some View {
        VStack(spacing: 24) {
            Text("AI Joke Generator")
                .font(.largeTitle)
                .fontWeight(.bold)

            if !joke.isEmpty {
                Text(joke)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
            }

            Button {
                generateJoke()
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isLoading ? "Thinking..." : "Tell me a joke")
                }
                .frame(minWidth: 200)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isLoading)
        }
        .padding()
    }

    private func generateJoke() {
        isLoading = true
        joke = ""

        Task {
            do {
                let response = try await session.respond(to: "Tell me a short, funny programming joke.")
                joke = response.content
            } catch {
                joke = "Error: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
}

#Preview {
    ContentView()
}
