//
//  ServiceProvider.swift
//  ReceiptValidator
//
//  Created by Yevhenii on 5/4/25.
//

import Foundation
import SwiftUI

/// A central service provider to manage dependencies
public class ServiceProvider: ObservableObject {
    // Singleton instance
    public static let shared = ServiceProvider()
    
    // MARK: - Services
    
    /// The camera service for capturing images
    @Published public private(set) var cameraService: CameraService
    
    /// The receipt validator service for validating receipts
    @Published public private(set) var receiptValidatorService: ReceiptValidatorServiceProtocol
    
    // MARK: - Initialization
    
    private init() {
        // Initialize services
        self.cameraService = CameraService()
        self.receiptValidatorService = ReceiptValidatorService()
    }
    
    // MARK: - Methods for testing
    
    /// Replace the receipt validator service with a mock implementation
    /// - Parameter mockService: The mock service to use
    public func setReceiptValidatorService(_ mockService: ReceiptValidatorServiceProtocol) {
        self.receiptValidatorService = mockService
    }
}

// MARK: - Environment Values

private struct ServiceProviderKey: EnvironmentKey {
    static let defaultValue = ServiceProvider.shared
}

extension EnvironmentValues {
    /// Access the service provider from the environment
    public var serviceProvider: ServiceProvider {
        get { self[ServiceProviderKey.self] }
        set { self[ServiceProviderKey.self] = newValue }
    }
}

extension View {
    /// Inject the service provider into the environment
    /// - Parameter serviceProvider: The service provider to inject
    /// - Returns: A view with the service provider in its environment
    public func withServiceProvider(_ serviceProvider: ServiceProvider = .shared) -> some View {
        environment(\.serviceProvider, serviceProvider)
    }
} 