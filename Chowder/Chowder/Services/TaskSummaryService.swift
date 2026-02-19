import FoundationModels

/// Generates short task titles from user messages using Apple's on-device Foundation Models.
actor TaskSummaryService {
    static let shared = TaskSummaryService()

    private init() {}

    /// Generate a 2-4 word title for the overall task represented by the conversation.
    /// Analyzes up to the last 5 user messages to identify the primary task, ignoring
    /// follow-up details like dates, confirmations, or clarifications.
    /// Returns nil if Foundation Models is unavailable or generation fails.
    func generateTitle(for messages: [String]) async -> String? {
        guard !messages.isEmpty else {
            print("📝 TaskSummaryService: No messages provided")
            return nil
        }
        
        let availability = SystemLanguageModel.default.availability
        guard availability == .available else {
            print("📝 TaskSummaryService: Model not available - \(availability)")
            return nil
        }

        let session = LanguageModelSession(model: .init(useCase: .general, guardrails: .permissiveContentTransformations))
        
        let numberedMessages = messages.enumerated().map { index, msg in
            "\(index + 1). \"\(msg)\""
        }.joined(separator: "\n")
        
        let prompt = """
        Analyze these user messages from a conversation with an AI assistant and identify the overall task being worked on. \
        It should read like the task that the assistant will perform based on the messages. \
        It should sound like an imperative command. Like "Verb, Adjective/Noun, Noun".

        Messages (oldest to newest):
        \(numberedMessages)

        The latest message may just be a follow-up (like a date, confirmation, or answer to a question). \
        Look at all messages to understand what the user is ultimately trying to accomplish.

        Give a short 2-4 word title for the overall task, not just the latest message. \
        Make the title specific to the details in the message. Dont use generic nouns. \
        Prioritise proper nouns and details that the user has sent.

        It is crucial that the title is succinct because it will be used in UI. Only output the title, nothing else.
        """

        do {
            let response = try await session.respond(to: prompt)
            return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }
}
