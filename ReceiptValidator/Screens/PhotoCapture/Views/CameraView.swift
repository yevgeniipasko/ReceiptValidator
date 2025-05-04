//
//  CameraView.swift
//  ReceiptValidator
//
//  Created by Yevhenii on 5/3/25.
//

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
            if let error = error {
                cameraService.handleCameraError(error: error)
            }
        }
        
        DispatchQueue.main.async {
            cameraService.setPreviewLayer(for: view)
        }
        
        return view
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        // Update preview layer frame when view updates
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
    
    public static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        // Remove preview layer when view is dismantled
        uiView.layer.sublayers?.forEach { layer in
            if layer is AVCaptureVideoPreviewLayer {
                layer.removeFromSuperlayer()
            }
        }
    }
    
    // Create a coordinator to manage the view's lifecycle
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject {
        var parent: CameraView
        
        public init(_ parent: CameraView) {
            self.parent = parent
        }
    }
} 
