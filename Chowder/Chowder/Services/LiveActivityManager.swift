import ActivityKit
import Foundation
import os.log

private let logger = Logger(subsystem: "app.chowder.Chowder", category: "LiveActivity")

/// Manages the Live Activity that shows agent thinking steps on the Lock Screen.
final class LiveActivityManager: @unchecked Sendable {

    static let shared = LiveActivityManager()

    private var currentActivity: Activity<ChowderActivityAttributes>?
    /// Accumulated completed step labels for the current run.
    private var completedStepLabels: [String] = []

    private init() {}

    // MARK: - Push Token Observation

    /// Start observing push-to-start tokens. Call this once at app launch.
    /// The token allows APNs to start a Live Activity remotely (iOS 17.2+).
    func observePushToStartToken() {
        Task {
            for await tokenData in Activity<ChowderActivityAttributes>.pushToStartTokenUpdates {
                let token = tokenData.hexString
                logger.notice("Push-to-Start Token: \(token, privacy: .public)")
            }
        }
    }

    /// Observe for activities started via push notification.
    /// This is needed to track activities that iOS creates from push-to-start.
    func observeActivityUpdates() {
        Task {
            for await activity in Activity<ChowderActivityAttributes>.activityUpdates {
                logger.notice("Activity update received! ID: \(activity.id, privacy: .public)")
                logger.notice("Activity state: \(String(describing: activity.content.state), privacy: .public)")
                
                // Observe push token for this activity
                observeActivityPushToken(for: activity)
            }
        }
    }

    /// Observe push token updates for the current activity.
    /// The token allows APNs to update/end an existing Live Activity.
    private func observeActivityPushToken(for activity: Activity<ChowderActivityAttributes>) {
        Task {
            for await tokenData in activity.pushTokenUpdates {
                let token = tokenData.hexString
                logger.notice("Activity Push Token (for updates): \(token, privacy: .public)")
            }
        }
    }

    // MARK: - Public API

    /// Start a new Live Activity when the user sends a message.
    /// - Parameters:
    ///   - agentName: The bot/agent display name.
    ///   - userTask: The message the user sent (truncated for display).
    func startActivity(agentName: String, userTask: String) {
        // End any stale activity from a previous run
        if currentActivity != nil {
            endActivity()
        }

        completedStepLabels = []

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("⚡ Live Activities not enabled — skipping")
            return
        }

        // Truncate the user task for the Lock Screen
        let truncatedTask = userTask.count > 60
            ? String(userTask.prefix(57)) + "..."
            : userTask

        let attributes = ChowderActivityAttributes(
            agentName: agentName,
            userTask: truncatedTask
        )
        let initialState = ChowderActivityAttributes.ContentState(
            currentStep: "Thinking...",
            completedSteps: [],
            isFinished: false
        )
        let content = ActivityContent(state: initialState, staleDate: nil)

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: .token
            )
            print("⚡ Live Activity started: \(currentActivity?.id ?? "?")")

            if let activity = currentActivity {
                observeActivityPushToken(for: activity)
            }
        } catch {
            print("⚡ Failed to start Live Activity: \(error.localizedDescription)")
        }
    }

    /// Update the Live Activity with a new current step and the latest completed steps.
    /// - Parameters:
    ///   - currentStep: Label of the step now in progress.
    ///   - completedSteps: Labels of all completed steps so far.
    func updateStep(_ currentStep: String, completedSteps: [String]) {
        guard let activity = currentActivity else { return }

        completedStepLabels = completedSteps

        let state = ChowderActivityAttributes.ContentState(
            currentStep: currentStep,
            completedSteps: completedSteps,
            isFinished: false
        )
        let content = ActivityContent(state: state, staleDate: nil)

        Task {
            await activity.update(content)
        }
    }

    /// End the Live Activity. Shows a brief "Done" state before dismissing.
    func endActivity() {
        guard let activity = currentActivity else { return }
        currentActivity = nil

        let finalState = ChowderActivityAttributes.ContentState(
            currentStep: "Done",
            completedSteps: completedStepLabels,
            isFinished: true
        )
        let content = ActivityContent(state: finalState, staleDate: nil)
        completedStepLabels = []

        Task {
            await activity.end(content, dismissalPolicy: .after(.now + 8))
            print("⚡ Live Activity ended")
        }
    }
}

// MARK: - Data Extension for Hex String

extension Data {
    /// Converts Data to a hexadecimal string representation (used for APNs tokens).
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
