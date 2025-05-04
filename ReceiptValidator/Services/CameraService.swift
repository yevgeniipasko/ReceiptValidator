//
//  CameraService.swift
//  ReceiptValidator
//
//  Created by Yevhenii on 5/3/25.
//

import SwiftUI
import UIKit
import AVFoundation

// This class will handle the camera access and photo taking functionality
public class CameraService: NSObject, ObservableObject {
    // Properties that trigger view updates should not be modified during view updates
    @Published public private(set) var image: UIImage?
    @Published public private(set) var showCaptureError = false
    @Published public private(set) var errorMessage = ""
    @Published public private(set) var captureSession: AVCaptureSession?
    @Published public private(set) var recentImage: UIImage?
    
    // Non-published properties for internal state management
    private var isConfiguring = false
    private var photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoCaptureCompletionBlock: ((UIImage?, Error?) -> Void)?
    
    public override init() {
        super.init()
    }
    
    // Check if the camera is available on the device
    public func checkCameraAvailability() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    // Configure the capture session for camera usage
    func startSession(completion: @escaping (Error?) -> Void) {
        // Create a local session object first
        let newSession = AVCaptureSession()
        
        // Use a background queue for configuration to avoid UI freezes
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            self.isConfiguring = true
            newSession.beginConfiguration()
            newSession.sessionPreset = .photo
            
            // Add video input
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
                newSession.commitConfiguration()
                self.isConfiguring = false
                DispatchQueue.main.async {
                    completion(NSError(domain: "CameraService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not create video device input"]))
                }
                return
            }
            
            guard newSession.canAddInput(videoDeviceInput) else {
                newSession.commitConfiguration()
                self.isConfiguring = false
                DispatchQueue.main.async {
                    completion(NSError(domain: "CameraService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not add video device input to the session"]))
                }
                return
            }
            newSession.addInput(videoDeviceInput)
            
            // Add photo output
            guard newSession.canAddOutput(self.photoOutput) else {
                newSession.commitConfiguration()
                self.isConfiguring = false
                DispatchQueue.main.async {
                    completion(NSError(domain: "CameraService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not add photo output to the session"]))
                }
                return
            }
            newSession.addOutput(self.photoOutput)
            newSession.commitConfiguration()
            self.isConfiguring = false
            
            // Start running the session
            newSession.startRunning()
            
            // Now that configuration is complete, update the published property on the main thread
            DispatchQueue.main.async {
                self.captureSession = newSession
                completion(nil)
            }
        }
    }
    
    // Initialize preview layer for displaying the camera feed
    func setPreviewLayer(for view: UIView) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let captureSession = self.captureSession else { return }
            
            // Create preview layer on main thread
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            
            // Remove any existing preview layers
            view.layer.sublayers?.forEach { layer in
                if layer is AVCaptureVideoPreviewLayer {
                    layer.removeFromSuperlayer()
                }
            }
            
            // Add new preview layer
            view.layer.addSublayer(previewLayer)
            self.previewLayer = previewLayer
        }
    }
    
    // Capture a photo
    func capturePhoto(completion: @escaping (UIImage?, Error?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self,
                  let captureSession = self.captureSession,
                  captureSession.isRunning else {
                DispatchQueue.main.async {
                    completion(nil, NSError(domain: "CameraService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Capture session is not running"]))
                }
                return
            }
            
            let settings = AVCapturePhotoSettings()
            
            // Store the completion handler
            self.photoCaptureCompletionBlock = completion
            
            // Capture the photo
            DispatchQueue.main.async {
                self.photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }
    
    // Stop the capture session safely
    func stopSession() {
        // Use a reference to the current session to avoid capturing self
        guard let session = captureSession else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // If in configuration, complete it first
            if self?.isConfiguring == true {
                session.commitConfiguration()
            }
            
            // Only stop if running
            if session.isRunning {
                session.stopRunning()
            }
            
            // Update the published property on the main thread
            DispatchQueue.main.async {
                self?.captureSession = nil
                self?.previewLayer = nil
            }
        }
    }
    
    // Create a UIImagePickerController for the photo library
    func configureLibraryPicker(delegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = delegate
        picker.allowsEditing = true
        return picker
    }
    
    // Handle any errors that occur during camera access
    func handleCameraError(error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.errorMessage = error.localizedDescription
            self.showCaptureError = true
        }
    }
    
    // Set captured image
    func setImage(_ image: UIImage) {
        DispatchQueue.main.async { [weak self] in
            self?.recentImage = image
        }
    }
}

// Extension to handle photo capture delegate methods
extension CameraService: AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.photoCaptureCompletionBlock?(nil, error)
            }
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            let error = NSError(domain: "CameraService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not create image from photo data"])
            DispatchQueue.main.async {
                self.photoCaptureCompletionBlock?(nil, error)
            }
            return
        }
        
        // Update properties on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.recentImage = image
            self.photoCaptureCompletionBlock?(image, nil)
        }
    }
} 
