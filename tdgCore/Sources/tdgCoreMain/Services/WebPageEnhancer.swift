//
//  WebPageEnhancer.swift
//  Three Daily Goals
//
//  Created by AI Assistant on 2025-01-24.
//

import Foundation
@preconcurrency import LinkPresentation

#if canImport(FoundationModels)
    import FoundationModels
#endif

#if os(macOS) || os(Linux)
    import Darwin
#endif

public final class WebPageEnhancer: Sendable {
    private let aiSession: LanguageModelSession?

    public init() {
        #if canImport(FoundationModels)
            // Avoid initializing FoundationModels when running as root or if unavailable
            // Running as root is not supported by FoundationModels; fall back gracefully
            let isRootUser: Bool = {
                #if os(macOS) || os(Linux)
                    return (getuid() == 0)
                #else
                    return false
                #endif
            }()

            if !isRootUser {
                let model = SystemLanguageModel.default
                if case .available = model.availability {
                    do {
                        self.aiSession = try LanguageModelSession()
                    } catch {
                        // If session creation fails for any reason, disable AI gracefully
                        self.aiSession = nil
                    }
                } else {
                    self.aiSession = nil
                }
            } else {
                self.aiSession = nil
            }
        #else
            self.aiSession = nil
        #endif
    }

    public var hasAI: Bool {
        return aiSession != nil
    }

    /// Extract metadata from URL and format an actionable task title
    /// - Parameter url: The URL to enhance
    /// - Parameter currentTitle: The current task title (e.g., "Read", "Watch", or empty)
    /// - Parameter useAI: Whether to use AI to improve the description (default: false)
    /// - Returns: Tuple with formatted title and description
    public func enhance(url: URL, currentTitle: String = "", useAI: Bool = false) async -> (
        title: String, description: String?
    ) {
        debugPrint("url: \(url)")

        var extractedTitle: String? = nil

        let metadataProvider = LPMetadataProvider()
        do {
            let metadata = try await metadataProvider.startFetchingMetadata(for: url)
            extractedTitle = metadata.title
        } catch {
            print("⚠️ Metadata extraction failed (share extension context?): \(error.localizedDescription)")
        }

        let titleToUse = extractedTitle ?? url.host ?? "Read"
        let formattedTitle = formatActionableTitle(currentTitle: currentTitle, extractedTitle: titleToUse)

        var description: String? = nil
        if useAI {
            description = await generateAISummary(url: url)
        } else {
            description = await fetchMetaDescription(url: url)
        }

        debugPrint("description: \(String(describing: description))")
        return (formattedTitle, description)
    }

    /// Format a title to be actionable by combining action verb with extracted title
    /// - Parameters:
    ///   - currentTitle: The current task title (e.g., "Read", "Watch", or empty)
    ///   - extractedTitle: The extracted webpage title
    /// - Returns: Formatted actionable title (e.g., "Read Swift Documentation")
    private func formatActionableTitle(currentTitle: String, extractedTitle: String) -> String {
        let trimmedCurrent = currentTitle.trimmingCharacters(in: .whitespaces)

        guard trimmedCurrent.isEmpty || trimmedCurrent.lowercased() == "read" else {
            // Preserve existing action verb: "[Action] [extracted title]"
            return "\(trimmedCurrent) \(extractedTitle)"
        }
        // Use "Read [title]" format
        return "Read \(extractedTitle)"
    }

    private func fetchMetaDescription(url: URL) async -> String? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else { return nil }

            // Look for meta description tag
            let patterns = [
                "<meta\\s+name=[\"']description[\"']\\s+content=[\"'](.*?)[\"']",
                "<meta\\s+content=[\"'](.*?)[\"']\\s+name=[\"']description[\"']",
                "<meta\\s+property=[\"']og:description[\"']\\s+content=[\"'](.*?)[\"']",
                "<meta\\s+name=[\"']twitter:description[\"']\\s+content=[\"'](.*?)[\"']",
            ]

            for pattern in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                    let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
                    let range = Range(match.range(at: 1), in: html)
                {
                    let desc = String(html[range])
                    if !desc.isEmpty {
                        return decodeHTMLEntities(desc)
                    }
                }
            }

            return nil
        } catch {
            return nil
        }
    }

    private func decodeHTMLEntities(_ text: String) -> String {
        var result = text
        let entities = [
            "&amp;": "&", "&lt;": "<", "&gt;": ">",
            "&quot;": "\"", "&#39;": "'", "&apos;": "'",
            "&nbsp;": " ",
        ]
        for (entity, char) in entities {
            result = result.replacingOccurrences(of: entity, with: char)
        }
        return result
    }

    private func extractMainText(from html: String) -> String {
        // Remove HTML tags and extract text
        var text = html
        text = text.replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func generateAISummary(url: URL) async -> String? {
        #if canImport(FoundationModels)
            guard let session = aiSession else { return await fetchMetaDescription(url: url) }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let html = String(data: data, encoding: .utf8) else {
                    return await fetchMetaDescription(url: url)
                }

                let mainText = extractMainText(from: html)
                guard !mainText.isEmpty else {
                    return await fetchMetaDescription(url: url)
                }

                // Limit text length for processing
                let truncated = String(mainText.prefix(4000))

                let prompt = """
                    Summarize the following webpage content in 2-3 sentences. Focus on the main points and key information:

                    \(truncated)
                    """

                let response = try await session.respond(to: prompt)
                return response.content
            } catch {
                print("⚠️ AI summary generation failed: \(error.localizedDescription)")
                return await fetchMetaDescription(url: url)
            }
        #else
            return await fetchMetaDescription(url: url)
        #endif
    }
}
