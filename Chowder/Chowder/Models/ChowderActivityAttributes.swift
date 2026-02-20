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
        /// Short subject line summarizing the task (latched from first thinking summary).
        var subject: String?
        /// The latest intent -- shown in the footer.
        var currentIntent: String
        /// SF Symbol name for the current intent's tool category.
        var currentIntentIcon: String?
        /// The previous intent -- shown as the top card.
        var previousIntent: String?
        /// The 2nd most previous intent -- shown as the card behind.
        var secondPreviousIntent: String?
        /// When the current intent started -- used for the live timer.
        var intentStartDate: Date
        /// When the current intent ended
        var intentEndDate: Date?
        /// Total step number (completed + current).
        var stepNumber: Int
        /// Formatted cost string (e.g. "$0.49"), nil until first usage event.
        var costTotal: String?
        /// Whether the agent has finished and the activity should dismiss.
        var isFinished: Bool {
            intentEndDate != nil
        }
    }
}

// MARK: - Preview Data

extension ChowderActivityAttributes {
    static var preview: ChowderActivityAttributes {
        ChowderActivityAttributes(
            agentName: "Larry",
            userTask: "I’ll go skiing next weekend."
        )
    }
}

extension ChowderActivityAttributes.ContentState {
    static var inProgress: ChowderActivityAttributes.ContentState {
        ChowderActivityAttributes.ContentState(
            subject: "Train to Margate",
            currentIntent: "Searching available trains",
            previousIntent: "Reading project files",
            secondPreviousIntent: "Identifying dependencies",
            intentStartDate: Date(),
            stepNumber: 3,
            costTotal: "$0.49"
        )
    }

    static var finished: ChowderActivityAttributes.ContentState {
        ChowderActivityAttributes.ContentState(
            subject: "Your train to Margate has been booked",
            currentIntent: "Complete",
            previousIntent: nil,
            secondPreviousIntent: nil,
            intentStartDate: Date(),
            intentEndDate: Date.now.addingTimeInterval(360),
            stepNumber: 5,
            costTotal: "$1.23"
        )
    }

    // MARK: - Progressive States (for cycling through)

    static var step1: ChowderActivityAttributes.ContentState {
        ChowderActivityAttributes.ContentState(
            subject: "Train to Margate",
            currentIntent: "Searched trains from London to Margate on June 15",
            previousIntent: nil,
            secondPreviousIntent: nil,
            intentStartDate: Date(),
            stepNumber: 1,
            costTotal: nil,
        )
    }

    static var step2: ChowderActivityAttributes.ContentState {
        ChowderActivityAttributes.ContentState(
            subject: "Train to Margate",
            currentIntent: "Comparing departure times and prices",
            previousIntent: "Searched trains from London to Margate on June 15",
            secondPreviousIntent: nil,
            intentStartDate: Date(),
            stepNumber: 2,
            costTotal: "$0.12",
        )
    }

    static var step3: ChowderActivityAttributes.ContentState {
        ChowderActivityAttributes.ContentState(
            subject: "Train to Margate",
            currentIntent: "Found the 10:15 departure—best price!",
            previousIntent: "Compared departure times and prices",
            secondPreviousIntent: "Searched trains from London to Margate on June 15",
            intentStartDate: Date(),
            stepNumber: 3,
            costTotal: "$0.34",
        )
    }

    static var step4: ChowderActivityAttributes.ContentState {
        ChowderActivityAttributes.ContentState(
            subject: "Train to Margate",
            currentIntent: "Entering passenger details",
            previousIntent: "Found the 10:15 departure—best price!",
            secondPreviousIntent: "Compared departure times and prices",
            intentStartDate: Date(),
            stepNumber: 4,
            costTotal: "$0.56",
        )
    }

    static var step5: ChowderActivityAttributes.ContentState {
        ChowderActivityAttributes.ContentState(
            subject: "Train to Margate",
            currentIntent: "Confirming booking",
            previousIntent: "Entering passenger details",
            secondPreviousIntent: "Found the 10:15 departure—best price!",
            intentStartDate: Date(),
            stepNumber: 5,
            costTotal: "$0.78",
        )
    }
}
