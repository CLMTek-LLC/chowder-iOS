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
                        Text(context.attributes.agentName)
                            .font(.headline)
                        Text(context.state.currentIntent)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if !context.state.isFinished {
                        Text("Step \(context.state.stepNumber)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if let prev = context.state.previousIntent, !context.state.isFinished {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.green)
                            Text(prev)
                                .font(.caption2)
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
    let state = context.state
    
    // Collect unique intents (filter out empty strings and duplicates)
    let intents: [String] = [state.secondPreviousIntent, state.previousIntent]
        .compactMap { $0 }
        .filter { !$0.isEmpty }
    
    let isWaiting = intents.isEmpty
    
    VStack(alignment: .leading, spacing: 4) {
        // Header: task + cost badge
        HStack(spacing: 10) {
            
            HStack {
                Image(.larry)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 21, height: 21)
                    .clipShape(.circle)
                    .overlay {
                        Circle()
                            .stroke(Color.black.opacity(0.12))
                    }
                
                Group {
                    if intents.isEmpty {
                        Text(context.attributes.agentName)
                    } else {
                        Text(state.subject ?? "Figuring it out")
                            .id(state.subject)
                    }
                }
                .font(.callout.bold())
                .foregroundStyle(.primary.opacity(0.72))
                .lineLimit(1)
                .transition(.blurReplace)
            }
            
            

            Spacer()
            
            
            if let cost = state.costTotal {
                let alert = !cost.contains("$0")
                Text(cost)
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .overlay {
                        Capsule()
                            .stroke(Color.black.opacity(alert ? 0.06 : 0.12))
                    }
                    .background(Color.black.opacity(alert ? 0.12 : 0), in: .capsule)
                    .monospacedDigit()
            } else {
                HStack(spacing: 5) {
                    Image(systemName: "circle.fill")
                        .resizable()
                        .foregroundStyle(.green)
                        .frame(width: 5, height: 5)
                        .symbolEffect(.pulse)
                    
                    Text("OpenClaw")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .font(.subheadline.bold())
        .frame(height: 28)
        .padding(.horizontal, 6)

        // Stacked cards for previous intents - keyed by the intent text itself
        ZStack {
            if intents.isEmpty {
                Text(context.attributes.userTask)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.blue)
//                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.blue.opacity(0.12), in: .rect(cornerRadius: 16, style: .continuous))
                    .overlay(alignment: .bottomTrailing, content: {
                        Image(.messageBubble)
                            .renderingMode(.template)
                            .offset(y: 10)
                            .foregroundStyle(.blue.opacity(0.12))
                    })
                    .padding(.leading, 48)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .transition(.blurReplace)
            }
            
            ForEach(intents, id: \.self) { intent in
                let isBehind = intent != state.previousIntent
                
                intentCard(text: intent, isBehind: isBehind)
            }
        }
        .frame(height: 70)
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .frame(maxHeight: .infinity)
        .zIndex(10)
        
        // Footer: current intent + timer
        HStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "safari")
                    .symbolVariant(.fill.circle)
                
                Text(isWaiting ? "Thinking…" : state.currentIntent)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
            .id(state.currentIntent)
            .transition(.blurReplace)
            
            Spacer()
            
            if !isWaiting && !state.isFinished {
                Text("00:00")
                    .opacity(0)
                    .overlay(alignment: .trailing) {
                        Text(state.intentStartDate, style: .timer)
                            .contentTransition(.numericText(countsDown: false))
                            .font(.subheadline.bold())
                            .monospacedDigit()
                            .opacity(0.5)
                    }
            }
        }
        .padding(.leading, 8)
        .padding(.trailing, 12)
        .font(.footnote.bold())
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 10)
    .frame(height: 160)
    .background(isWaiting ? Color.white : Color.black.opacity(0.18))
    .activityBackgroundTint(Color.white.opacity(isWaiting ? 1 : 0.12))
}

@ViewBuilder
private func intentCard(text: String, isBehind: Bool) -> some View {
    HStack(spacing: 10) {
        Image(systemName: "checkmark.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.green)
            .frame(width: 15)
        
        Text(text)
            .font(.callout)
            .foregroundStyle(.black)
            .frame(height: 60)
            .frame(maxWidth: .infinity, alignment: .leading)
        
        Image(systemName: "chevron.right")
            .font(.subheadline.bold())
            .opacity(0.5)
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .frame(height: 60)
    .background(Color.white, in: .rect(cornerRadius: isBehind ? 12 : 16, style: .continuous))
    .scaleEffect(isBehind ? 0.92 : 1)
    .offset(y: isBehind ? 10 : 0)
    .opacity(isBehind ? 0.72 : 1)
    .zIndex(isBehind ? 0 : 1)
    .transition(.asymmetric(
        insertion: .offset(y: 120),
        removal: .opacity.animation(.default.delay(0.3))
    ))
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
