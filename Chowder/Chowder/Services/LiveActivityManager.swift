import ActivityKit
import Foundation

/// Manages the Live Activity that shows agent thinking steps on the Lock Screen.
final class LiveActivityManager: @unchecked Sendable {

    static let shared = LiveActivityManager()

    private var currentActivity: Activity<ChowderActivityAttributes>?
    private var intentStartDate: Date = Date()

    private init() {}

    // MARK: - Public API

    /// Start a new Live Activity when the user sends a message.
    /// - Parameters:
    ///   - agentName: The bot/agent display name.
    ///   - userTask: The message the user sent (truncated for display).
    ///   - subject: Optional AI-generated subject to display immediately.
    func startActivity(agentName: String, userTask: String, subject: String? = nil) {
        if currentActivity != nil {
            endActivity()
        }

        intentStartDate = Date()

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("⚡ Live Activities not enabled — skipping")
            return
        }

        let attributes = ChowderActivityAttributes(
            agentName: agentName,
            userTask: userTask
        )
        let initialState = ChowderActivityAttributes.ContentState(
            subject: subject,
            currentIntent: "Thinking...",
            previousIntent: nil,
            secondPreviousIntent: nil,
            intentStartDate: intentStartDate,
            stepNumber: 1,
            costTotal: nil,
            isFinished: false
        )
        let content = ActivityContent(state: initialState, staleDate: nil)

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            print("⚡ Live Activity started: \(currentActivity?.id ?? "?")")
        } catch {
            print("⚡ Failed to start Live Activity: \(error.localizedDescription)")
        }
    }

    /// Update the Live Activity with full state from the caller.
    /// This is the primary update method used by ChatViewModel which manages its own state.
    /// - Parameters:
    ///   - subject: Subject line for the activity (AI-generated or latched from first intent).
    ///   - currentIntent: The current step label shown at the bottom.
    ///   - previousIntent: The most recent completed intent (yellow arrow).
    ///   - secondPreviousIntent: The 2nd most recent intent (grey, fading out).
    ///   - stepNumber: The total step count.
    ///   - costTotal: Formatted cost string (e.g. "$0.049").
    ///   - isAISubject: Whether the subject was AI-generated (for potential future use).
    func update(
        subject: String?,
        currentIntent: String,
        previousIntent: String?,
        secondPreviousIntent: String?,
        stepNumber: Int,
        costTotal: String?,
        isAISubject: Bool = false
    ) {
        guard let activity = currentActivity else { return }

        // Reset timer when intent changes
        intentStartDate = Date()

        let state = ChowderActivityAttributes.ContentState(
            subject: subject,
            currentIntent: currentIntent,
            previousIntent: previousIntent,
            secondPreviousIntent: secondPreviousIntent,
            intentStartDate: intentStartDate,
            stepNumber: stepNumber,
            costTotal: costTotal,
            isFinished: false
        )
        let content = ActivityContent(state: state, staleDate: nil)

        Task {
            await activity.update(content)
        }
    }

    /// Convenience method to update with just a new intent string.
    /// Shifts intents internally - use `update(...)` for full control.
    func updateIntent(_ intent: String) {
        guard currentActivity != nil else { return }
        // This is a simplified update - ChatViewModel manages full state
        update(
            subject: nil,
            currentIntent: intent,
            previousIntent: nil,
            secondPreviousIntent: nil,
            stepNumber: 1,
            costTotal: nil
        )
    }

    /// End the Live Activity. Shows a brief "Done" state before dismissing.
    func endActivity() {
        guard let activity = currentActivity else { return }
        currentActivity = nil

        let finalState = ChowderActivityAttributes.ContentState(
            subject: nil,
            currentIntent: "Complete",
            previousIntent: nil,
            secondPreviousIntent: nil,
            intentStartDate: intentStartDate,
            stepNumber: 0,
            costTotal: nil,
            isFinished: true
        )
        let content = ActivityContent(state: finalState, staleDate: nil)

        Task {
            await activity.end(content, dismissalPolicy: .after(.now + 8))
            print("⚡ Live Activity ended")
        }
    }
}
