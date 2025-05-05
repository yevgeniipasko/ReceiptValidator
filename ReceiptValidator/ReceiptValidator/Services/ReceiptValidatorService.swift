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
    private let confidenceThreshold: Float = 0.9

    /// The YOLO ML Model
    private var yoloModel: MLModel?

    /// VNCoreML Request
    private var visionRequest: VNCoreMLRequest?

    // MARK: - Initialization

    public init() {
        setupModel()
    }

    /// Sets up the YOLO ML model
    private func setupModel() {
        do {
            let model = try yolo11n_seg_receipt(configuration: MLModelConfiguration()).model
            self.yoloModel = model

            let visionModel = try VNCoreMLModel(for: model)

            let request = VNCoreMLRequest(model: visionModel) { request, error in
                if let error = error {
                    print("Vision request error: \(error.localizedDescription)")
                }
            }

            request.imageCropAndScaleOption = .scaleFill
            self.visionRequest = request
        } catch {
            print("Failed to load YOLO model: \(error)")
        }
    }

    // MARK: - Public Methods

    public func validateReceipt(image: UIImage, completion: @escaping (Result<ReceiptValidationResult, Error>) -> Void) {
        guard let visionRequest = visionRequest else {
            completion(.failure(ReceiptValidatorError.modelLoadingFailed))
            return
        }

        // Resize the image to match model input size (example: 640x640)
        let resizedImage = image.resize(to: CGSize(width: 640, height: 640))
        guard let ciImage = CIImage(image: resizedImage) else {
            completion(.failure(ReceiptValidatorError.invalidImageFormat))
            return
        }

        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])

        do {
            try handler.perform([visionRequest])

            guard let results = visionRequest.results as? [VNCoreMLFeatureValueObservation] else {
                completion(.failure(ReceiptValidatorError.predictionFailed("Unexpected result type.")))
                return
            }

            // Find "var_1365" which is detections output
            guard let detectionOutput = results.first(where: { $0.featureName == "var_1365" }),
                  let detections = detectionOutput.featureValue.multiArrayValue else {
                completion(.failure(ReceiptValidatorError.predictionFailed("No detections found.")))
                return
            }

            // Decode detections
            let result = processDetections(detections, originalImageSize: image.size)
            completion(.success(result))

        } catch {
            completion(.failure(ReceiptValidatorError.predictionFailed(error.localizedDescription)))
        }
    }

    public func validateReceipt(image: UIImage) async throws -> ReceiptValidationResult {
        return try await withCheckedThrowingContinuation { continuation in
            validateReceipt(image: image) { result in
                continuation.resume(with: result)
            }
        }
    }

    // MARK: - Helper Methods

    private func processDetections(_ detections: MLMultiArray, originalImageSize: CGSize) -> ReceiptValidationResult {
        let numElements = detections.shape[2].intValue
        var bestConfidence: Float = 0
        var bestBoundingBox: CGRect?

        for i in 0..<numElements {
            // YOLOv11 output: [x, y, width, height, confidence, class scores...]

            let confidence = detections[[0, 4, NSNumber(value: i)]].floatValue

            if confidence < confidenceThreshold {
                continue
            }

            let centerX = detections[[0, 0, NSNumber(value: i)]].floatValue
            let centerY = detections[[0, 1, NSNumber(value: i)]].floatValue
            let width = detections[[0, 2, NSNumber(value: i)]].floatValue
            let height = detections[[0, 3, NSNumber(value: i)]].floatValue

            // Convert from normalized center x/y to CGRect in image coordinates
            let rect = CGRect(
                x: CGFloat(centerX - width / 2) * originalImageSize.width,
                y: CGFloat(centerY - height / 2) * originalImageSize.height,
                width: CGFloat(width) * originalImageSize.width,
                height: CGFloat(height) * originalImageSize.height
            )

            if confidence > bestConfidence {
                bestConfidence = confidence
                bestBoundingBox = rect
            }
        }

        if let boundingBox = bestBoundingBox {
            return ReceiptValidationResult(
                isReceipt: true,
                confidence: bestConfidence,
                segmentationMask: nil, // segmentation processing is TODO (p output)
                boundingBox: boundingBox
            )
        } else {
            return ReceiptValidationResult(
                isReceipt: false,
                confidence: 0.0,
                segmentationMask: nil,
                boundingBox: nil
            )
        }
    }
}
