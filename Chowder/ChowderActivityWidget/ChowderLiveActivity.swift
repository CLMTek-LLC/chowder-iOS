import ActivityKit
import SwiftUI
import WidgetKit

struct ChowderLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ChowderActivityAttributes.self) { context in
            // Lock Screen / StandBy banner
            lockScreenBanner(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded region (long-press on Dynamic Island)
                DynamicIslandExpandedRegion(.leading) {
                    PulsingDot(isFinished: context.state.isFinished)
                        .frame(width: 12, height: 12)
                        .padding(.top, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.attributes.agentName)
                            .font(.headline)
                        Text(context.state.currentStep)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if !context.state.isFinished && !context.state.completedSteps.isEmpty {
                        Text("Step \(context.state.completedSteps.count + 1)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if !context.state.completedSteps.isEmpty {
                        VStack(alignment: .leading, spacing: 3) {
                            ForEach(context.state.completedSteps.suffix(4), id: \.self) { step in
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(.green)
                                    Text(step)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            } compactLeading: {
                PulsingDot(isFinished: context.state.isFinished)
                    .frame(width: 8, height: 8)
            } compactTrailing: {
                if context.state.isFinished {
                    Text("Done")
                        .font(.caption2)
                        .foregroundStyle(.green)
                } else {
                    Text(context.state.currentStep)
                        .font(.caption2)
                        .lineLimit(1)
                        .frame(maxWidth: 64)
                }
            } minimal: {
                PulsingDot(isFinished: context.state.isFinished)
                    .frame(width: 8, height: 8)
            }
        }
    }
}

// MARK: - Lock Screen Banner

@ViewBuilder
private func lockScreenBanner(context: ActivityViewContext<ChowderActivityAttributes>) -> some View {
    let steps = context.state.completedSteps.suffix(5)
    
    VStack(alignment: .leading, spacing: 8) {
        // Header: pulsing dot + agent name + task
        HStack(spacing: 10) {
            Text(context.attributes.userTask)
                .font(.callout.bold())
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()
            
            Text(steps.count > 2 ? "$11.23" : "$0.49")
                .foregroundStyle(.white)
                .font(.subheadline)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .overlay {
                    Capsule()
                        .stroke(Color.white.opacity(0.24))
                }
                .background(steps.count > 2 ? Color.red : Color.black, in: .capsule)

            
        }
        .padding(.leading, 8)

        ZStack {
            ForEach(Array(steps.enumerated()), id: \.self.element) { (index, step) in
                let isPrevious = index == steps.count - 2
                let isOld = index < steps.count - 2
                
                if !isOld {
                    HStack(spacing: 10) {
                        Circle()
                            .stroke(.black.opacity(0.18), lineWidth: 3)
                            .frame(width: 15)
                        
                        Text(step)
                            .font(.callout)
                            .foregroundStyle(.black)
                            .frame(height: 60)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Image(systemName: "chevron.right")
                            .font(.subheadline.bold())
                            .opacity(0.5)
                    }
                    .transition(.asymmetric(insertion: .offset(y: 120), removal: .opacity.animation(.default.delay(2))))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 60)
                    .background(Color.white, in: .rect(cornerRadius: isPrevious ? 12 : 16, style: .continuous))
                    .scaleEffect(isPrevious ? 0.92 : 1)
                    .offset(y: isPrevious ? 10 : 0)
                    .opacity(isPrevious ? 0.72 : 1)
                }
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 10)
        
        HStack(spacing: 6) {
            Image(systemName: "safari.fill")
            Text("Using the browser")
                .font(.callout.bold())
                .foregroundStyle(.white)
                .lineLimit(1)
            Spacer()
            Text("02:11")
                .opacity(0.5)
        }
        .font(.subheadline.bold())
        .foregroundStyle(.white)
        .padding(.leading, 8)
        .padding(.trailing, 12)
    }
    .padding(12)
    .background(Color.black)
    .activityBackgroundTint(.black.opacity(0.2))
}

// MARK: - Pulsing Dot

/// A small circle that gently scales up and down to indicate activity.
struct PulsingDot: View {
    var isFinished: Bool

    var body: some View {
        Circle()
            .fill(isFinished ? Color.green : Color.blue)
    }
}

// MARK: - Previews

#Preview("Lock Screen - In Progress", as: .content, using: ChowderActivityAttributes.preview) {
    ChowderLiveActivity()
} contentStates: {
    ChowderActivityAttributes.ContentState.step1
    ChowderActivityAttributes.ContentState.step2
    ChowderActivityAttributes.ContentState.step3
    ChowderActivityAttributes.ContentState.step4
    ChowderActivityAttributes.ContentState.step5
    ChowderActivityAttributes.ContentState.finished
}

#Preview("Lock Screen - Finished", as: .content, using: ChowderActivityAttributes.preview) {
    ChowderLiveActivity()
} contentStates: {
    ChowderActivityAttributes.ContentState.finished
}

#Preview("Dynamic Island Compact", as: .dynamicIsland(.compact), using: ChowderActivityAttributes.preview) {
    ChowderLiveActivity()
} contentStates: {
    ChowderActivityAttributes.ContentState.inProgress
    ChowderActivityAttributes.ContentState.finished
}

#Preview("Dynamic Island Minimal", as: .dynamicIsland(.minimal), using: ChowderActivityAttributes.preview) {
    ChowderLiveActivity()
} contentStates: {
    ChowderActivityAttributes.ContentState.inProgress
    ChowderActivityAttributes.ContentState.finished
}

#Preview("Dynamic Island Expanded", as: .dynamicIsland(.expanded), using: ChowderActivityAttributes.preview) {
    ChowderLiveActivity()
} contentStates: {
    ChowderActivityAttributes.ContentState.inProgress
    ChowderActivityAttributes.ContentState.finished
}
