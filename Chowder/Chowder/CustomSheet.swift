//
//  CustomSheet.swift
//  Chowder
//
//  Created by Vedant Gurav on 17/02/2026.
//

import SwiftUI

struct MessageItem: Identifiable {
    let id = UUID()
    let text: String
    let isSent: Bool
}

struct SheetContent: View {
    @Binding var progress: CGFloat
    let isFocused: Bool
    
    @GestureState var isDragging = false
    
    var showBackground: Bool {
        isDragging || progress > 0
    }
    
    let minHeight: CGFloat = 76
    var maxHeight: CGFloat { isFocused ? UIScreen.main.bounds.height * 1 / 3 : UIScreen.main.bounds.height / 2 }
    var fullTranslation: CGFloat { maxHeight - minHeight }
    
    var body: some View {
        VStack {
            
            Spacer()
        }
        .frame(minHeight: minHeight, alignment: .bottom)
        .frame(height: minHeight + progress * fullTranslation, alignment: .bottom)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .top) {
            Capsule()
                .foregroundStyle(.tertiary)
                .frame(width: 36, height: 4)
        }
        .padding(8)
        .contentShape(.rect)
        .background(alignment: .bottom) {
            ZStack {
                if showBackground {
                    UnevenRoundedRectangle(
                        cornerRadii: .init(
                            topLeading: 40,
                            bottomLeading: 60,
                            bottomTrailing: 60,
                            topTrailing: 40
                        ),
                        style: .continuous
                    )
                    .fill(Color.white)
                    .overlay(
                        UnevenRoundedRectangle(
                            cornerRadii: .init(
                                topLeading: 40,
                                bottomLeading: 60,
                                bottomTrailing: 60,
                                topTrailing: 40
                            ),
                            style: .continuous
                        )
                        .stroke(Color.black.opacity(0.06))
                    )
                    .compositingGroup()
                    .shadow(color: .black.opacity(0.24), radius: 24, x: 0, y: -4)
                    .transition(.offset(y: 140))
                    .padding(4)
                }
            }
            .ignoresSafeArea()
        }
        .animation(.smooth(duration: 0.4), value: showBackground)
        .gesture(
            DragGesture(coordinateSpace: .global)
                .updating($isDragging, body: { _, s, _ in
                    s = true
                })
                .onChanged({ v in
                    let currentProgress = min(1, max(0, -v.translation.height / fullTranslation))
                    withAnimation(.smooth(duration: 0.1)) {
                        progress = currentProgress
                    }
                })
                .onEnded({ v in
                    let currentProgress = min(1, max(0, -v.predictedEndTranslation.height / fullTranslation))
                    withAnimation(.smooth(duration: 0.3)) {
                        progress = currentProgress > 0.5 ? 1 : 0
                    }
                })
        )
    }
}

struct CustomSheet: View {
    let messages: [MessageItem] = [
        MessageItem(text: "Hi! I'm your OpenClaw assistant. How can I help you today?", isSent: false),
        MessageItem(text: "I need to book a flight to New York", isSent: true),
        MessageItem(text: "I'd be happy to help you book a flight to New York. When would you like to travel?", isSent: false),
        MessageItem(text: "March 15th, returning on the 20th", isSent: true),
        MessageItem(text: "Got it. And which city will you be departing from?", isSent: false),
        MessageItem(text: "San Francisco", isSent: true),
        MessageItem(text: "I found 12 flights from SFO to JFK on March 15th. Would you prefer morning or evening departure?", isSent: false),
        MessageItem(text: "Morning would be best", isSent: true),
        MessageItem(text: "Here are your top options:\n\n• United UA 234 - 7:15 AM - $389\n• Delta DL 512 - 8:30 AM - $412\n• JetBlue B6 918 - 9:00 AM - $367", isSent: false),
        MessageItem(text: "The JetBlue one looks good", isSent: true),
        MessageItem(text: "Excellent choice! JetBlue B6 918 departing at 9:00 AM, arriving at 5:42 PM. Would you like economy or extra legroom?", isSent: false),
        MessageItem(text: "Economy is fine", isSent: true),
        MessageItem(text: "Perfect. I've selected the same return flight for March 20th. Your total comes to $734 roundtrip. Ready to proceed with booking?", isSent: false),
        MessageItem(text: "Yes, let's do it!", isSent: true),
        MessageItem(text: "Your booking is confirmed! ✈️ Confirmation #OCLW7823. I've sent the details to your email.", isSent: false),
    ]
    
    @State var progress: CGFloat = 0
    
    @FocusState var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(messages) { message in
                                MessageItemBubble(message: message)
                            }
                            Spacer()
                                .frame(height: 76)
                                .id("endSpacer")
                        }
                        .padding()
                    }
                    .contentMargins(.bottom, 76, for: .scrollIndicators)
                    .onTapGesture {
                        isFocused = false
                    }
                    .onAppear {
                        proxy.scrollTo("endSpacer", anchor: .bottom)
                    }
                    .onChange(of: isFocused) { oldValue, newValue in
                        withAnimation {
                            proxy.scrollTo("endSpacer", anchor: .bottom)
                        }
                    }
                    .onChange(of: progress) { oldValue, newValue in
                        if newValue == 0 || newValue == 1 {
                            proxy.scrollTo("endSpacer", anchor: .bottom)
                        }
                    }
                }
                
                HStack(spacing: 10) {
                    Button {
                        withAnimation(.smooth(duration: 0.2)) {
                            progress = 1
                        }
                    } label: {
                        Image(systemName: "plus")
                            .bold()
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.12), in: .circle)
                            .offset(x: -28 * progress)
                            .opacity(1.0 - progress * 2.0)
                            .scaleEffect(1 - progress * 0.5)
                            .blur(radius: progress * 8)
                            .foregroundStyle(Color.black)
                    }
                        
                    
                    TextField("Message", text: .constant(""), prompt: Text("OddJob is ready"))
                        .focused($isFocused)
                        .frame(maxHeight: .infinity)
                        .padding(.horizontal, 8 - progress * 44)
                    
                    Image(systemName: "arrow.up")
                        .bold()
                        .frame(width: 44, height: 44)
                        .foregroundStyle(Color.white)
                        .background(Color.black.opacity(0.12), in: .circle)
                }
                .padding()
                .background {
                    Capsule()
                        .fill(Color.white)
                        .overlay(Capsule().stroke(Color.black.opacity(0.06)))
                        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
                        .opacity(progress)
                }
                .frame(height: 76)
                .padding(.horizontal, 16 * progress)
                .frame(height: 80, alignment: .bottom)
                .padding(.bottom, isFocused ? 4 : 0)
                .background(alignment: .bottom) {
                    SheetContent(progress: $progress, isFocused: isFocused)
                }
                .background(alignment: .bottom) {
                    VStack(spacing: 0) {
                        LinearGradient(colors: [.clear, .white], startPoint: .top, endPoint: .bottom)
                            .frame(height: 40)
                        Color.white
                            .ignoresSafeArea()
                    }
                    .padding(.top, -32)
                }
            }
            .navigationTitle("Odd Job")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct MessageItemBubble: View {
    let message: MessageItem
    
    var body: some View {
        HStack {
            if message.isSent {
                Spacer(minLength: 60)
            }
            
            Text(message.text)
                .padding(.horizontal, message.isSent ? 14 : 0)
                .padding(.vertical, 10)
                .background(message.isSent ? Color.blue : Color.clear)
                .foregroundColor(message.isSent ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            
            if !message.isSent {
                Spacer(minLength: 60)
            }
        }
    }
}

#Preview {
    CustomSheet()
}
