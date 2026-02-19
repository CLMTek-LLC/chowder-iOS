import ActivityKit
import Foundation

/// Manages the Live Activity that shows agent thinking steps on the Lock Screen.
final class LiveActivityManager: @unchecked Sendable {

    static let shared = LiveActivityManager()

    private var currentActivity: Activity<ChowderActivityAttributes>?
    /// Track intents for stacking display
    private var currentIntent: String = ""
    private var previousIntent: String?
    private var secondPreviousIntent: String?
    private var stepNumber: Int = 0
    private var intentStartDate: Date = Date()
    private var subject: String?
    private var costTotal: String?

    private init() {}

    // MARK: - Public API

    /// Start a new Live Activity when the user sends a message.
    /// - Parameter subject: Optional AI-generated subject to display immediately.
    func startActivity(agentName: String, userTask: String, subject: String? = nil) {
        if currentActivity != nil {
            endActivity()
        }

        // Reset tracking state
        currentIntent = "Thinking..."
        previousIntent = nil
        secondPreviousIntent = nil
        stepNumber = 1
        intentStartDate = Date()
        subject = nil
        costTotal = nil

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("⚡ Live Activities not enabled — skipping")
            return
        }

        let truncatedTask = userTask.count > 60
            ? String(userTask.prefix(57)) + "..."
            : userTask

        let attributes = ChowderActivityAttributes(
            agentName: agentName,
            userTask: truncatedTask
        )
        let initialState = ChowderActivityAttributes.ContentState(
            subject: nil,
            currentIntent: currentIntent,
            previousIntent: nil,
            secondPreviousIntent: nil,
            intentStartDate: intentStartDate,
            stepNumber: stepNumber,
            costTotal: nil,
            isFinished: false
        )
        lastState = initialState
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

    /// Update the Live Activity with a new intent.
    /// - Parameters:
    ///   - intent: The new current intent description.
    ///   - subject: Optional subject line (latched from first thinking summary).
    ///   - cost: Optional formatted cost string (e.g. "$0.49").
    func updateIntent(_ intent: String, subject: String? = nil, cost: String? = nil) {
        guard let activity = currentActivity else { return }

        // Shift intents down the stack
        secondPreviousIntent = previousIntent
        previousIntent = currentIntent
        currentIntent = intent
        stepNumber += 1
        intentStartDate = Date()
        
        // Latch subject from first non-nil value
        if self.subject == nil, let newSubject = subject {
            self.subject = newSubject
        }
        
        // Update cost if provided
        if let newCost = cost {
            self.costTotal = newCost
        }

        let state = ChowderActivityAttributes.ContentState(
            subject: self.subject,
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

    /// Update just the cost without changing intents.
    /// - Parameter cost: The formatted cost string (e.g. "$0.49").
    func updateCost(_ cost: String) {
        guard let activity = currentActivity else { return }
        
        costTotal = cost

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
        lastState = state
        let content = ActivityContent(state: state, staleDate: nil)

        Task {
            await currentActivity?.update(content)
        }
    }

    /// End the Live Activity. Shows a brief "Done" state before dismissing.
    func endActivity() {
        guard let activity = currentActivity else { return }
        currentActivity = nil

        let finalState = ChowderActivityAttributes.ContentState(
            subject: subject,
            currentIntent: "Complete",
            previousIntent: previousIntent,
            secondPreviousIntent: nil,
            intentStartDate: intentStartDate,
            stepNumber: stepNumber,
            costTotal: costTotal,
            isFinished: true
        )
        lastState = nil
        lastIntentText = ""
        latchedSubject = nil
        subjectIsFromAI = false
        let content = ActivityContent(state: finalState, staleDate: nil)

        // Reset tracking state
        currentIntent = ""
        previousIntent = nil
        secondPreviousIntent = nil
        stepNumber = 0
        subject = nil
        costTotal = nil

        Task {
            await activity.end(content, dismissalPolicy: .after(.now + 8))
            print("⚡ Live Activity ended")
        }
    }
}
