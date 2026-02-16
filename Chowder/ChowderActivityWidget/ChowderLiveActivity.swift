import ActivityKit
import SwiftUI
import WidgetKit

struct ChowderLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ChowderActivityAttributes.self) { context in
            lockScreenBanner(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Circle()
                        .fill(context.state.isFinished ? Color.green : Color.blue)
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.attributes.userTask)
                            .font(.system(size: 15, weight: .medium))
                            .lineLimit(1)
                        if !context.state.isFinished {
                            Text(context.state.currentIntent)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Step \(context.state.stepNumber)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if let prev = context.state.previousIntent, !context.state.isFinished {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.turn.down.right")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.yellow)
                            Text(prev)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            } compactLeading: {
                Circle()
                    .fill(context.state.isFinished ? Color.green : Color.blue)
                    .frame(width: 6, height: 6)
            } compactTrailing: {
                if context.state.isFinished {
                    Text("Done")
                        .font(.caption2)
                        .foregroundStyle(.green)
                } else {
                    Text(context.state.currentIntent)
                        .font(.caption2)
                        .lineLimit(1)
                        .frame(maxWidth: 64)
                }
            } minimal: {
                Circle()
                    .fill(context.state.isFinished ? Color.green : Color.blue)
                    .frame(width: 6, height: 6)
            }
        }
    }

    // MARK: - Lock Screen Banner

    @ViewBuilder
    private func lockScreenBanner(context: ActivityViewContext<ChowderActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Row 1: User task + Cost ──
            HStack {
                Text(context.attributes.userTask)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Spacer()

                if let cost = context.state.costTotal {
                    Text(cost)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                        )
                }
            }
            .padding(.bottom, 16)

            // ── Row 2: Intent scroll stack ──
            VStack(alignment: .leading, spacing: 0) {
                // 2nd previous intent -- grey check, fading out
                if let secondPrev = context.state.secondPreviousIntent, !context.state.isFinished {
                    HStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 16, height: 16)
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.gray.opacity(0.4))
                        }
                        Text(secondPrev)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.white.opacity(0.1))
                            .lineLimit(1)
                    }
                    .transition(.push(from: .bottom))
                }

                // Previous intent -- yellow arrow + "..."
                if let prev = context.state.previousIntent, !context.state.isFinished {
                    HStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(Color.yellow)
                                .frame(width: 22, height: 22)
                            Image(systemName: "arrow.turn.down.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.black)
                        }
                        Text(prev + "...")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .mask(ShimmerMask())
                    }
                    .transition(.push(from: .bottom))
                }

                // Done state
                if context.state.isFinished {
                    HStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 22, height: 22)
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.black)
                        }
                        Text("Done")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.bottom, 20)

            // ── Row 3: Current intent (ALL CAPS) + Timer + Step ──
            HStack {
                if !context.state.isFinished {
                    Text(context.state.currentIntent)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                        .textCase(.uppercase)
                        .lineLimit(1)
                        .contentTransition(.numericText())

                    Text(
                        timerInterval: context.state.intentStartDate...Date.now.addingTimeInterval(3600),
                        countsDown: false
                    )
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 56, alignment: .leading)
                }

                Spacer()

                Text("Step \(context.state.stepNumber)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
        }
        .padding(16)
        .activityBackgroundTint(.black)
    }
}

// MARK: - Shimmer Mask

/// A gradient mask that gives a soft shimmer effect on the active intent text.
struct ShimmerMask: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: .white.opacity(0.4), location: 0),
                .init(color: .white, location: 0.3),
                .init(color: .white, location: 0.7),
                .init(color: .white.opacity(0.4), location: 1.0)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
