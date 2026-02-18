//
//  Sheet.swift
//  Chowder
//
//  Created by Vedant Gurav on 17/02/2026.
//

import SwiftUI

struct Sheet: View {
    @State private var isSheetExpanded: Bool = false
    @State private var messages: [String] = []
    
    var body: some View {
        // Main content
        ScrollView {
            VStack(spacing: 16) {
                Text("Chowder")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 60)
                
                Text("Tap the + button or drag up to expand the sheet")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Display sent messages
                ForEach(messages, id: \.self) { message in
                    HStack {
                        Text(message)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 200) // Space for the sheet
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .persistentBottomSheet(
            isExpanded: $isSheetExpanded,
            collapsedHeight: 100,
            expandedHeight: 400,
            placeholder: "OddJob is ready",
            onSendMessage: { message in
                messages.append(message)
            },
            onSelectImages: { images in
                print("Selected \(images.count) images")
            }
        )
    }
}

#Preview {
    Sheet()
}
