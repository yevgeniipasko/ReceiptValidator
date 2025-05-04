//
//  ReceiptValidatorProtocol.swift
//  ReceiptValidator
//
//  Created by Yevhenii on 5/4/25.
//

import UIKit
import CoreML
import Vision

/// Result of receipt validation
public struct ReceiptValidationResult: Equatable {
    /// Whether the image contains a receipt
    public let isReceipt: Bool
    
    /// Confidence score (0.0 - 1.0) if a receipt was detected
    public let confidence: Float
    
    /// Optional segmentation mask for the receipt if detected
    public let segmentationMask: UIImage?
    
    /// Bounding box of the receipt in normalized coordinates (if detected)
    public let boundingBox: CGRect?
    
    /// Implement Equatable manually since UIImage doesn't conform to Equatable
    public static func == (lhs: ReceiptValidationResult, rhs: ReceiptValidationResult) -> Bool {
        return lhs.isReceipt == rhs.isReceipt &&
               lhs.confidence == rhs.confidence &&
               lhs.boundingBox == rhs.boundingBox
        // Note: we're intentionally not comparing segmentationMask since UIImage doesn't conform to Equatable
    }
}

/// Protocol defining the receipt validation service capabilities
public protocol ReceiptValidatorServiceProtocol {
    /// Validates if an image contains a receipt
    /// - Parameter image: The UIImage to validate
    /// - Parameter completion: Completion handler that returns the validation result or an error
    func validateReceipt(image: UIImage, completion: @escaping (Result<ReceiptValidationResult, Error>) -> Void)
    
    /// Validates if an image contains a receipt (synchronous version using async/await)
    /// - Parameter image: The UIImage to validate
    /// - Returns: The validation result
    /// - Throws: Error if validation fails
    func validateReceipt(image: UIImage) async throws -> ReceiptValidationResult
} 