
// CameraCaptureView.swift

import SwiftUI

struct CameraCaptureView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var cameraService = CameraService()
    @Binding var image: UIImage?

    var body: some View {
        ZStack {
            CameraView(cameraService: cameraService)
                .ignoresSafeArea()

            VStack {
                Spacer()

                if cameraService.isCapturing {
                    ProgressView("Capturing...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                } else if cameraService.isCameraReady {
                    Button(action: {
                        cameraService.capturePhoto { capturedImage, error in
                            if let error = error {
                                print("Capture error: \(error.localizedDescription)")
                                return
                            }

                            if let capturedImage = capturedImage {
                                self.image = capturedImage
                                dismiss()

                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    cameraService.stopSession()
                                }
                            }
                        }
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .padding()
                            .shadow(radius: 5)
                    }
                } else {
                    ProgressView("Camera starting...")
                        .padding()
                }
            }
        }
    }
}
