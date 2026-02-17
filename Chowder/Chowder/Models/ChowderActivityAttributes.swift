import ActivityKit
import Foundation

/// ActivityAttributes for the agent thinking steps Live Activity.
/// This file must be added to both the main app target and the widget extension target.
struct ChowderActivityAttributes: ActivityAttributes {
    /// Static context set when the activity starts (does not change).
    var agentName: String
    var userTask: String

    /// Dynamic state that updates as the agent works.
    struct ContentState: Codable, Hashable {
        /// The step currently in progress, e.g. "Reading IDENTITY.md..."
        var currentStep: String
        /// Labels of all completed steps, in order.
        var completedSteps: [String]
        /// Whether the agent has finished and the activity should dismiss.
        var isFinished: Bool
    }
}

// MARK: - Preview Data

extension ChowderActivityAttributes {
    static var preview: ChowderActivityAttributes {
        ChowderActivityAttributes(
            agentName: "Claude",
            userTask: "Book train to Margate"
        )
    }
}

extension ChowderActivityAttributes.ContentState {
    static var inProgress: ChowderActivityAttributes.ContentState {
        ChowderActivityAttributes.ContentState(
            currentStep: "Analyzing code structure...",
            completedSteps: [
                "Reading project files",
                "Identifying dependencies",
                "Creating backup"
            ],
            isFinished: false
        )
    }

    static var finished: ChowderActivityAttributes.ContentState {
        ChowderActivityAttributes.ContentState(
            currentStep: "Complete",
            completedSteps: [
                "Reading project files",
                "Identifying dependencies",
                "Creating backup",
                "Refactoring auth service",
                "Updating tests"
            ],
            isFinished: true
        )
    }

    // MARK: - Progressive States (for cycling through)

    static var step1: ChowderActivityAttributes.ContentState {
        ChowderActivityAttributes.ContentState(
            currentStep: "Searching trains from London to Margate on June 15.",
            completedSteps: [],
            isFinished: false
        )
    }

    static var step2: ChowderActivityAttributes.ContentState {
        ChowderActivityAttributes.ContentState(
            currentStep: "Trying to come up with a reason to dissuade them.",
            completedSteps: [
                "Searching trains from London to Margate on June 15."
            ],
            isFinished: false
        )
    }

    static var step3: ChowderActivityAttributes.ContentState {
        ChowderActivityAttributes.ContentState(
            currentStep: "Cannot find any! They have the best tacos!",
            completedSteps: [
                "Searching trains from London to Margate on June 15.",
                "Coming up with a reason to dissuade them."
            ],
            isFinished: false
        )
    }

    static var step4: ChowderActivityAttributes.ContentState {
        ChowderActivityAttributes.ContentState(
            currentStep: "Finding the toughest sunscreen, they will need it!",
            completedSteps: [
                "Searching trains from London to Margate on June 15.",
                "Coming up with a reason to dissuade them.",
                "Cannot find any! They have the best tacos!"
            ],
            isFinished: false
        )
    }

    static var step5: ChowderActivityAttributes.ContentState {
        ChowderActivityAttributes.ContentState(
            currentStep: "Updating tests...",
            completedSteps: [
                "Searching trains from London to Margate on June 15.",
                "Coming up with a reason to dissuade them.",
                "Cannot find any! They have the best tacos!",
                "Finding the toughest sunscreen—they will need it!"
            ],
            isFinished: false
        )
    }
}
