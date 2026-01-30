// LLMResponseFilter - LLM Module
// Copyright 2026

import Foundation

/// Filters and cleans LLM responses
public enum LLMResponseFilter {
    /// Removes thinking tags and unwraps XML wrappers from LLM output
    public static func filter(_ text: String) -> String {
        var processedText = text

        // Step 1: Remove thinking/reasoning tags WITH their content (discard AI's chain-of-thought)
        let thinkingPatterns = [
            #"(?s)<thinking>(.*?)</thinking>"#,
            #"(?s)<think>(.*?)</think>"#,
            #"(?s)<reasoning>(.*?)</reasoning>"#
        ]

        for pattern in thinkingPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(processedText.startIndex..., in: processedText)
                processedText = regex.stringByReplacingMatches(in: processedText, options: [], range: range, withTemplate: "")
            }
        }

        processedText = processedText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Step 2: Unwrap any XML tags that wrap the entire text (keep content, remove wrapper)
        processedText = unwrapOuterXMLTags(processedText)

        return processedText
    }

    private static func unwrapOuterXMLTags(_ text: String) -> String {
        // Match pattern like <TAG>content</TAG> where TAG wraps the entire text
        let pattern = #"^<([A-Za-z_][A-Za-z0-9_]*)>\s*([\s\S]*?)\s*</\1>$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let contentRange = Range(match.range(at: 2), in: text) else {
            return text
        }
        return String(text[contentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
