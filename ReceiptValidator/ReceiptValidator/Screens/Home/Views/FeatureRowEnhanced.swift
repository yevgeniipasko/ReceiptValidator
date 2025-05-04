//
//  FeatureRowEnhanced.swift
//  ReceiptValidator
//
//  Created by Yevhenii on 5/4/25.
//

import SwiftUI

/// Enhanced feature row with animations and styling
public struct FeatureRowEnhanced: View {
    var icon: String
    var text: String
    @State private var isHovered = false
    
    public var body: some View {
        HStack(spacing: 15) {
            // Icon with circle background
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue.opacity(0.2), .purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
            }
            .scaleEffect(isHovered ? 1.1 : 1.0)
            .animation(.spring(response: 0.3), value: isHovered)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.blue.opacity(isHovered ? 0.05 : 0))
                .animation(.easeOut(duration: 0.2), value: isHovered)
        )
        #if os(macOS)
        .onHover(perform: { hovering in
            isHovered = hovering
        })
        #endif
    }
} 
