//
//  PhotoViewModel.swift
//  ReceiptValidator
//
//  Created by Yevhenii on 5/3/25.
//
//  DEPRECATED: This ViewModel is deprecated and replaced by the integrated approach in HomeView.
//  Use HomeViewModel and CameraCaptureView instead.

import SwiftUI
import UIKit
import AVFoundation

public class PhotoViewModel: NSObject, ObservableObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // Reference to the camera service
    public let cameraService = CameraService()
    
    // Published properties
    @Published public var showImagePicker = false
    @Published public var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @Published public var capturedImage: UIImage?
    @Published public var showErrorAlert = false
    @Published public var errorMessage = ""
    @Published public var isProcessingImage = false
    @Published public var isCapturing = false
    @Published public var isCameraActive = false
    @Published public var shouldDismissScreen = false
    
    public override init() {
        super.init()
    }
    
    // Check if the camera is available on this device
    public var isCameraAvailable: Bool {
        return AVCaptureDevice.authorizationStatus(for: .video) == .authorized || 
               AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined
    }
    
    // Request camera permissions
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        default:
            completion(false)
        }
    }
    
    // Start camera session
    func activateCamera() {
        requestCameraPermission { [weak self] granted in
            guard let self = self else { return }
            
            if granted {
                DispatchQueue.main.async {
                    self.isCameraActive = true
                }
            } else {
                self.showError(message: "Camera access is required to take photos.")
            }
        }
    }
    
    // Take a photo using our custom camera
    func takePhoto() {
        isCapturing = true
        
        cameraService.capturePhoto { [weak self] image, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isCapturing = false
                
                if let error = error {
                    self.showError(message: error.localizedDescription)
                } else if let image = image {
                    self.handleCapturedImage(image)
                }
            }
        }
    }
    
    // Process a captured image and clean up camera resources
    private func handleCapturedImage(_ image: UIImage) {
        self.capturedImage = image
        
        // Clean up camera session on main thread after getting the image
        DispatchQueue.main.async {
            self.isCameraActive = false
            self.cameraService.stopSession()
            self.processImage(image)
        }
    }
    
    // Open photo library to select an image
    func selectPhoto() {
        sourceType = .photoLibrary
        showImagePicker = true
    }
    
    // Create the appropriate image picker for photo library
    func makeImagePicker() -> UIImagePickerController {
        return cameraService.configureLibraryPicker(delegate: self)
    }
    
    // Handle selected image from UIImagePickerController
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else {
            showError(message: "Couldn't select the image")
            return
        }
        
        self.capturedImage = selectedImage
        processImage(selectedImage)
    }
    
    // Handle cancellation
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    // Process the captured image (placeholder for future receipt processing logic)
    private func processImage(_ image: UIImage) {
        isProcessingImage = true
        
        // Simulate processing time
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isProcessingImage = false
            // Add actual image processing logic here when needed
        }
    }
    
    // Display an error message
    private func showError(message: String) {
        errorMessage = message
        showErrorAlert = true
    }
    
    // Explicitly cancel camera operations and clean up resources, then navigate back
    func cancelCamera() {
        DispatchQueue.main.async {
            self.isCameraActive = false
            
            // Delay stopping the session to ensure we're not in the middle of configuration
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.cameraService.stopSession()
                
                // Trigger navigation back to home screen with a slight delay for animations
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.shouldDismissScreen = true
                }
            }
        }
    }
    
    // Clean up resources when leaving the screen
    func cleanup() {
        if isCameraActive {
            cancelCamera()
        } else {
            cameraService.stopSession()
        }
    }
} 
