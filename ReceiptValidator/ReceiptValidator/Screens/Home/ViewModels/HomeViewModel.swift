//
//  HomeViewModel.swift
//  ReceiptValidator
//
//  Created by Yevhenii on 5/3/25.
//

import Foundation
import SwiftUI

public class HomeViewModel: ObservableObject {
    @Published public var features: [FeatureItem] = [
        FeatureItem(icon: "camera.viewfinder", text: "Instant receipt detection"),
        FeatureItem(icon: "lock.shield", text: "Secure validation"),
        FeatureItem(icon: "doc.text.magnifyingglass", text: "AI-powered recognition")
    ]
    
    @Published public var capturedImage: UIImage?
    
    public init() {}
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