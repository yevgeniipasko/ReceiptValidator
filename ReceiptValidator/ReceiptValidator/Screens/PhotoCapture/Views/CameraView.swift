
// CameraView.swift

import SwiftUI
import UIKit
import AVFoundation

public struct CameraView: UIViewRepresentable {

    @ObservedObject var cameraService: CameraService

    public init(cameraService: CameraService) {
        self.cameraService = cameraService
    }

    public func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black

        cameraService.startSession { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Camera error: \(error.localizedDescription)")
                } else {
                    self.cameraService.setPreviewLayer(for: view)
                }
            }
        }

        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first(where: { $0 is AVCaptureVideoPreviewLayer }) as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }

    public static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        uiView.layer.sublayers?.forEach { layer in
            if layer is AVCaptureVideoPreviewLayer {
                layer.removeFromSuperlayer()
            }
        }

        coordinator.parent.cameraService.stopSession()
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject {
        var parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }
    }
}
