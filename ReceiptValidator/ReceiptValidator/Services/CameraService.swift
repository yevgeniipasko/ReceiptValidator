//
//  CameraService.swift
//  ReceiptValidator
//

import SwiftUI
import UIKit
import AVFoundation

public class CameraService: NSObject, ObservableObject {
    @Published public private(set) var image: UIImage?
    @Published public private(set) var showCaptureError = false
    @Published public private(set) var errorMessage = ""
    @Published public private(set) var captureSession: AVCaptureSession?
    @Published public private(set) var recentImage: UIImage?

    // Session-specific photo output
    private var activePhotoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoCaptureCompletionBlock: ((UIImage?, Error?) -> Void)?
    private var isConfiguring = false

    public override init() {
        super.init()
    }

    public func checkCameraAvailability() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    func startSession(completion: @escaping (Error?) -> Void) {
        let newSession = AVCaptureSession()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            self.isConfiguring = true
            newSession.beginConfiguration()
            newSession.sessionPreset = .photo

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

            let photoOutput = AVCapturePhotoOutput()
            guard newSession.canAddOutput(photoOutput) else {
                newSession.commitConfiguration()
                self.isConfiguring = false
                DispatchQueue.main.async {
                    completion(NSError(domain: "CameraService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not add photo output to the session"]))
                }
                return
            }

            newSession.addOutput(photoOutput)
            self.activePhotoOutput = photoOutput

            newSession.commitConfiguration()
            self.isConfiguring = false

            newSession.startRunning()

            DispatchQueue.main.async {
                self.captureSession = newSession
                completion(nil)
            }
        }
    }

    func setPreviewLayer(for view: UIView) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let captureSession = self.captureSession else { return }

            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill

            view.layer.sublayers?.forEach { layer in
                if layer is AVCaptureVideoPreviewLayer {
                    layer.removeFromSuperlayer()
                }
            }

            view.layer.addSublayer(previewLayer)
            self.previewLayer = previewLayer
        }
    }

    func capturePhoto(completion: @escaping (UIImage?, Error?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self,
                  let captureSession = self.captureSession,
                  captureSession.isRunning,
                  let photoOutput = self.activePhotoOutput else {
                DispatchQueue.main.async {
                    completion(nil, NSError(domain: "CameraService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Capture session is not running or output not available"]))
                }
                return
            }

            let settings = AVCapturePhotoSettings()
            self.photoCaptureCompletionBlock = completion

            DispatchQueue.main.async {
                photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    func stopSession() {
        guard let session = captureSession else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if self?.isConfiguring == true {
                session.commitConfiguration()
            }

            if session.isRunning {
                session.stopRunning()
            }

            DispatchQueue.main.async {
                self?.captureSession = nil
                self?.activePhotoOutput = nil
                self?.previewLayer = nil
            }
        }
    }

    func configureLibraryPicker(delegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = delegate
        picker.allowsEditing = true
        return picker
    }

    func handleCameraError(error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = error.localizedDescription
            self?.showCaptureError = true
        }
    }

    func setImage(_ image: UIImage) {
        DispatchQueue.main.async { [weak self] in
            self?.recentImage = image
        }
    }
}

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

        DispatchQueue.main.async { [weak self] in
            self?.recentImage = image
            self?.photoCaptureCompletionBlock?(image, nil)
        }
    }
}
