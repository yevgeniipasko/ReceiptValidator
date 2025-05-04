//
//  ReceiptValidatorService.swift
//  ReceiptValidator
//
//  Created by Yevhenii on 5/4/25.
//

import UIKit
import CoreML
import Vision

/// Errors that can occur during receipt validation
public enum ReceiptValidatorError: Error {
    case modelLoadingFailed
    case preprocessingFailed
    case predictionFailed(String)
    case invalidImageFormat
    case lowConfidence
}

/// Service for validating receipts using the YOLOv11n-seg model
public class ReceiptValidatorService: ObservableObject, ReceiptValidatorServiceProtocol {
    // MARK: - Properties
    
    /// The confidence threshold for receipt detection (0.0 - 1.0)
    private let confidenceThreshold: Float = 0.5
    
    /// The YOLO ML Model
    private var yoloModel: MLModel?
    
    /// VNCoreML Request for object detection
    private var visionRequest: VNCoreMLRequest?
    
    // MARK: - Initialization
    
    public init() {
        setupModel()
    }
    
    /// Sets up the YOLO ML model
    private func setupModel() {
        do {
            // Get URL to the model in the bundle
            guard let modelURL = Bundle.main.url(forResource: "yolo11n-seg-receipt", withExtension: "mlpackage") else {
                print("Failed to find model in bundle")
                return
            }
            
            // Load the compiled model
            let compiledModelURL = try MLModel.compileModel(at: modelURL)
            let model = try MLModel(contentsOf: compiledModelURL)
            self.yoloModel = model
            
            // Set up Vision request
            let visionModel = try VNCoreMLModel(for: model)
            
            let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
                guard error == nil else {
                    print("Vision request error: \(error!.localizedDescription)")
                    return
                }
            }
            
            // Configure the request
            request.imageCropAndScaleOption = .scaleFill
            self.visionRequest = request
            
        } catch {
            print("Failed to load YOLO model: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Public Methods
    
    /// Validates if an image contains a receipt
    /// - Parameters:
    ///   - image: The UIImage to validate
    ///   - completion: Completion handler with the result
    public func validateReceipt(image: UIImage, completion: @escaping (Result<ReceiptValidationResult, Error>) -> Void) {
        // Ensure we have a valid model and request
        guard let visionRequest = visionRequest else {
            completion(.failure(ReceiptValidatorError.modelLoadingFailed))
            return
        }
        
        // Convert UIImage to CIImage for Vision processing
        guard let ciImage = CIImage(image: image) else {
            completion(.failure(ReceiptValidatorError.invalidImageFormat))
            return
        }
        
        // Create a handler for processing the image
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        // Perform the request
        do {
            try handler.perform([visionRequest])
            
            // Process results
            guard let results = visionRequest.results as? [VNRecognizedObjectObservation],
                  !results.isEmpty else {
                // No detections found
                completion(.success(ReceiptValidationResult(
                    isReceipt: false,
                    confidence: 0.0,
                    segmentationMask: nil,
                    boundingBox: nil
                )))
                return
            }
            
            // Get the most confident detection
            if let bestResult = results.max(by: { $0.confidence < $1.confidence }) {
                let isReceipt = bestResult.confidence >= self.confidenceThreshold
                
                // Extract segmentation mask if available (requires additional processing)
                var segmentationMask: UIImage? = nil
                if isReceipt {
                    segmentationMask = self.processSegmentationMask(from: bestResult, for: image)
                }
                
                // Extract the bounding box
                let boundingBox = bestResult.boundingBox
                
                completion(.success(ReceiptValidationResult(
                    isReceipt: isReceipt,
                    confidence: bestResult.confidence,
                    segmentationMask: segmentationMask,
                    boundingBox: boundingBox
                )))
            } else {
                completion(.success(ReceiptValidationResult(
                    isReceipt: false,
                    confidence: 0.0,
                    segmentationMask: nil,
                    boundingBox: nil
                )))
            }
            
        } catch {
            completion(.failure(ReceiptValidatorError.predictionFailed(error.localizedDescription)))
        }
    }
    
    /// Async version of receipt validation
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
    
    // MARK: - Helper Methods
    
    /// Converts a segmentation mask to a UIImage
    /// - Parameters:
    ///   - maskPixelBuffer: The pixel buffer containing the mask
    ///   - originalImageSize: The size of the original image
    /// - Returns: UIImage representation of the mask
    private func createMaskImage(from maskPixelBuffer: CVPixelBuffer, originalImageSize: CGSize) -> UIImage? {
        // This is a placeholder for actual mask processing logic
        // Implement based on the specific format of the segmentation mask from the model
        return nil
    }
    
    /// Process YOLO segmentation mask from a VNRecognizedObjectObservation
    /// - Parameters:
    ///   - observation: The object observation containing segmentation data
    ///   - originalImage: The original image the observation was made on
    /// - Returns: A UIImage containing the segmentation mask
    func processSegmentationMask(from observation: VNRecognizedObjectObservation, for originalImage: UIImage) -> UIImage? {
        // YOLO segmentation masks are typically stored in a pixel buffer
        // For each detected object in YOLO-seg models
        
        // Create a context to draw the mask
        UIGraphicsBeginImageContextWithOptions(originalImage.size, false, originalImage.scale)
        defer { UIGraphicsEndImageContext() }
        
        let context = UIGraphicsGetCurrentContext()
        
        // Draw the original image
        originalImage.draw(at: .zero)
        
        // Get the bounding box in the coordinate space of the original image
        let boundingBox = VNImageRectForNormalizedRect(
            observation.boundingBox,
            Int(originalImage.size.width),
            Int(originalImage.size.height)
        )
        
        // Set up drawing parameters for the mask overlay
        context?.setStrokeColor(UIColor.green.cgColor)
        context?.setLineWidth(3.0)
        context?.stroke(boundingBox)
        
        // Apply a transparent overlay on the detected area
        context?.setFillColor(UIColor(red: 0, green: 1, blue: 0, alpha: 0.3).cgColor)
        context?.fill(boundingBox)
        
        // Get the result image with the overlay
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// Process YOLOv11 specific segmentation data
    /// - Parameters:
    ///   - segmentationData: Raw segmentation data from the model
    ///   - boundingBox: The bounding box of the detected object
    ///   - imageSize: The size of the original image
    /// - Returns: A UIImage mask
    func processYOLOSegmentationData(_ segmentationData: Any, boundingBox: CGRect, imageSize: CGSize) -> UIImage? {
        // Implementation depends on specific format of YOLOv11n-seg model output
        // This would require testing with actual model output to correctly implement
        
        // Example implementation (placeholder):
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        // Draw a rectangle representing the mask as a placeholder
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor(red: 0, green: 1, blue: 0, alpha: 0.5).cgColor)
        
        let scaledBox = VNImageRectForNormalizedRect(boundingBox, Int(imageSize.width), Int(imageSize.height))
        context?.fill(scaledBox)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
} 