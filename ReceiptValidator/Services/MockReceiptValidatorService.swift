//
//  MockReceiptValidatorService.swift
//  ReceiptValidator
//
//  Created by Yevhenii on 5/4/25.
//

import UIKit

/// A mock implementation of the ReceiptValidatorServiceProtocol for testing
public class MockReceiptValidatorService: ReceiptValidatorServiceProtocol {
    /// Whether to simulate a receipt being detected
    private let shouldDetectReceipt: Bool
    
    /// The confidence score to return
    private let confidenceScore: Float
    
    /// Whether to simulate an error
    private let shouldError: Bool
    
    /// The error to return if shouldError is true
    private let error: Error?
    
    /// Initializer for the mock service
    /// - Parameters:
    ///   - shouldDetectReceipt: Whether to simulate a receipt being detected
    ///   - confidenceScore: The confidence score to return (0.0 - 1.0)
    ///   - shouldError: Whether to simulate an error
    ///   - error: The error to return if shouldError is true
    public init(
        shouldDetectReceipt: Bool = true,
        confidenceScore: Float = 0.85,
        shouldError: Bool = false,
        error: Error? = nil
    ) {
        self.shouldDetectReceipt = shouldDetectReceipt
        self.confidenceScore = confidenceScore
        self.shouldError = shouldError
        self.error = error
    }
    
    /// Mock implementation of the validateReceipt method
    /// - Parameters:
    ///   - image: The UIImage to validate
    ///   - completion: Completion handler with the result
    public func validateReceipt(image: UIImage, completion: @escaping (Result<ReceiptValidationResult, Error>) -> Void) {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if self.shouldError {
                completion(.failure(self.error ?? ReceiptValidatorError.predictionFailed("Mock error")))
                return
            }
            
            // Create a mock bounding box
            let boundingBox = self.shouldDetectReceipt ? CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6) : nil
            
            // Create a mock segmentation mask if a receipt is detected
            var segmentationMask: UIImage? = nil
            if self.shouldDetectReceipt {
                UIGraphicsBeginImageContextWithOptions(image.size, false, 1.0)
                defer { UIGraphicsEndImageContext() }
                
                let context = UIGraphicsGetCurrentContext()
                let rect = CGRect(
                    x: image.size.width * 0.2,
                    y: image.size.height * 0.2,
                    width: image.size.width * 0.6,
                    height: image.size.height * 0.6
                )
                
                context?.setFillColor(UIColor(red: 0, green: 1, blue: 0, alpha: 0.3).cgColor)
                context?.fill(rect)
                
                segmentationMask = UIGraphicsGetImageFromCurrentImageContext()
            }
            
            // Return the mock result
            let result = ReceiptValidationResult(
                isReceipt: self.shouldDetectReceipt,
                confidence: self.shouldDetectReceipt ? self.confidenceScore : 0.0,
                segmentationMask: segmentationMask,
                boundingBox: boundingBox
            )
            
            completion(.success(result))
        }
    }
    
    /// Mock implementation of the async validateReceipt method
    /// - Parameter image: The UIImage to validate
    /// - Returns: The validation result
    /// - Throws: Error if validation fails
    public func validateReceipt(image: UIImage) async throws -> ReceiptValidationResult {
        return try await withCheckedThrowingContinuation { continuation in
            validateReceipt(image: image) { result in
                continuation.resume(with: result)
            }
        }
    }
} 