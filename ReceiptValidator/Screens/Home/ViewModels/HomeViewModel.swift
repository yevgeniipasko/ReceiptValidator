//
//  HomeViewModel.swift
//  ReceiptValidator
//
//  Created by Yevhenii on 5/3/25.
//

import Foundation
import SwiftUI

public class HomeViewModel: ObservableObject {
    @Published public var isAnimating: Bool = false
    @Published public var features: [FeatureItem] = [
        FeatureItem(icon: "checkmark.circle.fill", text: "Quick scan and verification"),
        FeatureItem(icon: "lock.fill", text: "Secure and private"),
        FeatureItem(icon: "doc.plaintext", text: "Text recognition")
    ]
    
    public init() {}
    
    public func startAnimation() {
        isAnimating = true
    }
}

public struct FeatureItem: Identifiable {
    public let id = UUID()
    public let icon: String
    public let text: String
    
    public init(icon: String, text: String) {
        self.icon = icon
        self.text = text
    }
} 