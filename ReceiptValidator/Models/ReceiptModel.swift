//
//  ReceiptModel.swift
//  ReceiptValidator
//
//  Created by Yevhenii on 5/3/25.
//

import Foundation

struct Receipt: Identifiable {
    let id: UUID = UUID()
    let date: Date
    let amount: Double
    let vendor: String
    let items: [ReceiptItem]
    
    // Additional metadata can be added here
}

struct ReceiptItem: Identifiable {
    let id: UUID = UUID()
    let name: String
    let price: Double
    let quantity: Int
} 