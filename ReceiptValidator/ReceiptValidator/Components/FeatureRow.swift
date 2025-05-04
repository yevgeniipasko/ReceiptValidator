//
//  FeatureRow.swift
//  ReceiptValidator
//
//  Created by Yevhenii on 5/3/25.
//

import SwiftUI

public struct FeatureRow: View {
    public var icon: String
    public var text: String
    
    public init(icon: String, text: String) {
        self.icon = icon
        self.text = text
    }
    
    public var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.blue)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    FeatureRow(icon: "checkmark.circle.fill", text: "Sample feature")
} 