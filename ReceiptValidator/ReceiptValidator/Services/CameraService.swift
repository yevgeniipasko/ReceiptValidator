
// CameraService.swift

import SwiftUI
import UIKit
import AVFoundation

public class CameraService: NSObject, ObservableObject {
    @Published public private(set) var image: UIImage?
    @Published public private(set) var showCaptureError = false
    @Published public private(set) var errorMessage = ""
    @Published public private(set) var captureSession: AVCaptureSession?
    @Published public private(set) var recentImage: UIImage?
    @Published public private(set) var isCapturing = false
    @Published public private(set) var isSessionRunning = false
    @Published public private(set) var isCameraReady = false

    private var activePhotoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoCaptureCompletionBlock: ((UIImage?, Error?) -> Void)?
    private var isConfiguring = false
    private var cachedPhotoSettings: AVCapturePhotoSettings?
    private var captureTimeoutTimer: Timer?

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

            let settings = AVCapturePhotoSettings()
            if #available(iOS 16.0, *) {
                settings.maxPhotoDimensions = .init(width: 0, height: 0)
            } else if photoOutput.isHighResolutionCaptureEnabled {
                settings.isHighResolutionPhotoEnabled = true
            }
            if photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
                settings.embeddedThumbnailPhotoFormat = [AVVideoCodecKey: AVVideoCodecType.jpeg]
            }
            settings.flashMode = .off
            settings.isDepthDataDeliveryEnabled = false
            settings.isPortraitEffectsMatteDeliveryEnabled = false

            self.cachedPhotoSettings = settings

            newSession.commitConfiguration()
            self.isConfiguring = false

            newSession.startRunning()

            DispatchQueue.main.async {
                self.captureSession = newSession
                self.isSessionRunning = true
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

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                if previewLayer.connection?.isEnabled == true {
                    self?.isCameraReady = true
                }
            }
        }
    }

    func capturePhoto(completion: @escaping (UIImage?, Error?) -> Void) {
        guard let captureSession = self.captureSession,
              captureSession.isRunning,
              let photoOutput = self.activePhotoOutput else {
            completion(nil, NSError(domain: "CameraService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Camera is not ready"]))
            return
        }

        if isCapturing {
            completion(nil, NSError(domain: "CameraService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Already capturing photo"]))
            return
        }

        guard let settings = cachedPhotoSettings else {
            completion(nil, NSError(domain: "CameraService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Photo settings not prepared"]))
            return
        }

        isCapturing = true
        self.photoCaptureCompletionBlock = { [weak self] image, error in
            self?.isCapturing = false
            self?.captureTimeoutTimer?.invalidate()
            self?.captureTimeoutTimer = nil
            completion(image, error)
        }

        DispatchQueue.main.async { [weak self] in
            self?.captureTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
                if self?.isCapturing == true {
                    self?.photoCaptureCompletionBlock?(nil, NSError(domain: "CameraService", code: 999, userInfo: [NSLocalizedDescriptionKey: "Capture timeout - photo capture took too long"]))
                }
            }
        }

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func stopSession(completion: (() -> Void)? = nil) {
        guard let session = captureSession else {
            DispatchQueue.main.async {
                completion?()
            }
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if self?.isConfiguring == true {
                session.commitConfiguration()
            }

            if session.isRunning {
                session.stopRunning()
            }

            DispatchQueue.main.async {
                self?.captureSession = nil
                self?.isSessionRunning = false
                self?.activePhotoOutput = nil
                self?.previewLayer = nil
                self?.isCameraReady = false
                completion?()
            }
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
            DispatchQueue.main.async {
                self.photoCaptureCompletionBlock?(nil, NSError(domain: "CameraService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not create image from photo data"]))
            }
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.recentImage = image
            self?.photoCaptureCompletionBlock?(image, nil)
        }
    }
}
