//
//  ReceiptValidatorApp.swift
//  ReceiptValidator
//
//  Created by Yevhenii on 5/4/25.
//

import SwiftUI

@main
struct ReceiptValidatorApp: App {
    // Initialize the service provider
    @StateObject private var serviceProvider = ServiceProvider.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .withServiceProvider(serviceProvider) // Inject service provider into environment
        }
    }
}
