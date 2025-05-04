# Receipt Validator

A Swift app for capturing and validating receipts using the YOLOv11n-seg-receipt model.

## Features

- Camera capture functionality
- ML-powered receipt validation
- Receipt segmentation
- Clean architecture with protocol-based services

## ML Model

The app uses a YOLOv11n-seg model specifically trained to detect receipts. The model is packaged as an MLPackage resource in the app bundle.

### Integrating the ML Model

To ensure the model is properly included in your app bundle:

1. Add the `yolo11n-seg-receipt.mlpackage` to your Xcode project
2. Make sure it's included in the target's "Copy Bundle Resources" build phase
3. The model will be loaded at runtime by the `ReceiptValidatorService`

## Architecture

The app follows a clean architecture approach with the following components:

- **Services**: Handles business logic and external interactions
  - `CameraService`: Manages camera access and image capture
  - `ReceiptValidatorService`: Processes images using the ML model to validate receipts
  
- **Models**: Data structures for the app
  - `ReceiptValidationResult`: Holds the result of receipt validation

- **Protocols**: Defines contracts for services
  - `ReceiptValidatorServiceProtocol`: Interface for receipt validation

- **Views**: User interface components
  - `ContentView`: Main app view
  - `CameraView`: Camera capture interface

## Using the Receipt Validator Service

```swift
// Get the service from the service provider
let receiptValidatorService = ServiceProvider.shared.receiptValidatorService

// Validate an image
receiptValidatorService.validateReceipt(image: capturedImage) { result in
    switch result {
    case .success(let validationResult):
        // Process validation result
        if validationResult.isReceipt {
            // Receipt was detected
            let confidence = validationResult.confidence
            let boundingBox = validationResult.boundingBox
            let segmentationMask = validationResult.segmentationMask
            
            // Use these results for your UI or further processing
        } else {
            // No receipt was detected
        }
    case .failure(let error):
        // Handle error
    }
}

// OR using async/await
do {
    let validationResult = try await receiptValidatorService.validateReceipt(image: capturedImage)
    // Process validation result
} catch {
    // Handle error
}
```

## Testing

The app includes a mock implementation of the receipt validator service for testing:

```swift
// Create a mock service
let mockService = MockReceiptValidatorService(
    shouldDetectReceipt: true,
    confidenceScore: 0.9,
    shouldError: false
)

// Replace the real service with the mock
ServiceProvider.shared.setReceiptValidatorService(mockService)
```

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.5+

## License

This project is licensed under the MIT License. 