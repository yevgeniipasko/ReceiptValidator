//
//  CameraCaptureView.swift
//  ReceiptValidator
//
//  Created by Yevhenii on 5/4/25.
//

import SwiftUI
import AVFoundation

/// A view for capturing photos using the device camera
public struct CameraCaptureView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.serviceProvider) private var serviceProvider
    @Binding var image: UIImage?
    
    public var body: some View {
        ZStack {
            // Camera preview
            CameraView(cameraService: serviceProvider.cameraService)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                HStack {
                    // Cancel button
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    Spacer()
                    
                    // Capture button
                    Button(action: {
                        capturePhoto()
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.3), lineWidth: 2)
                                    .frame(width: 60, height: 60)
                            )
                    }
                    
                    Spacer()
                    
                    // Spacer to balance layout
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 30, height: 30)
                        .padding()
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            // Start camera session when view appears
            serviceProvider.cameraService.startSession { error in
                if let error = error {
                    print("Camera error: \(error)")
                }
            }
        }
        .onDisappear {
            // Stop camera session when view disappears
            serviceProvider.cameraService.stopSession()
        }
    }
    
    // Capture photo using camera service
    private func capturePhoto() {
        serviceProvider.cameraService.capturePhoto { capturedImage, error in
            if let error = error {
                print("Photo capture error: \(error)")
                return
            }
            
            if let capturedImage = capturedImage {
                // Set the captured image and dismiss the camera view
                self.image = capturedImage
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
} 
