//
//  PhotoScreenView.swift
//  ReceiptValidator
//
//  Created by Yevhenii on 5/3/25.
//

import SwiftUI

public struct PhotoScreenView: View {
    @StateObject private var viewModel = PhotoViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    public init() {}
    
    // Animation properties
    @State private var cameraAppears = false
    @State private var controlsOpacity = 1.0
    @State private var captureButtonScale = 1.0
    @State private var selectionScreenOpacity = 1.0
    @Namespace private var buttonTransition
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                    .animation(.easeOut, value: viewModel.isCameraActive)
                
                if viewModel.isCameraActive {
                    // Full-screen camera view
                    ZStack {
                        CameraView(cameraService: viewModel.cameraService)
                            .ignoresSafeArea()
                            .transition(
                                .asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 1.05)),
                                    removal: .opacity.combined(with: .scale(scale: 0.95))
                                )
                            )
                        
                        // Camera UI overlay
                        VStack {
                            // Top controls
                            HStack {
                                Button(action: {
                                    withAnimation(.easeOut(duration: 0.25)) {
                                        controlsOpacity = 0
                                        captureButtonScale = 0.8
                                    }
                                    viewModel.cancelCamera()
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Circle().fill(Color.black.opacity(0.5)))
                                }
                                .padding(.leading, 20)
                                .padding(.top, 10)
                                .opacity(controlsOpacity)
                                .animation(.easeInOut(duration: 0.3), value: controlsOpacity)
                                
                                Spacer()
                                
                                // Flash toggle button (placeholder)
                                Button(action: {
                                    // Would toggle flash here
                                }) {
                                    Image(systemName: "bolt.slash.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Circle().fill(Color.black.opacity(0.5)))
                                }
                                .padding(.trailing, 20)
                                .padding(.top, 10)
                                .opacity(controlsOpacity)
                                .animation(.easeInOut(duration: 0.3), value: controlsOpacity)
                            }
                            
                            Spacer()
                            
                            // Camera controls
                            VStack(spacing: 30) {
                                // Guide text
                                Text("Position receipt in frame")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(Color.black.opacity(0.5)))
                                
                                HStack(spacing: 60) {
                                    // Cancel button
                                    Button(action: {
                                        withAnimation(.easeOut(duration: 0.25)) {
                                            controlsOpacity = 0
                                            captureButtonScale = 0.8
                                        }
                                        viewModel.cancelCamera()
                                    }) {
                                        Text("Cancel")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                    .opacity(controlsOpacity)
                                    .animation(.easeInOut(duration: 0.3), value: controlsOpacity)
                                    
                                    // Capture button
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            captureButtonScale = 0.8
                                            controlsOpacity = 0.7
                                        }
                                        
                                        viewModel.takePhoto()
                                        
                                        // Restore scale after the photo is taken
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.2)) {
                                            captureButtonScale = 1.0
                                        }
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.white.opacity(0.2))
                                                .frame(width: 80, height: 80)
                                            
                                            Circle()
                                                .strokeBorder(Color.white, lineWidth: 3)
                                                .frame(width: 70, height: 70)
                                            
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 60, height: 60)
                                        }
                                    }
                                    .scaleEffect(captureButtonScale * (viewModel.isCapturing ? 0.8 : 1.0))
                                    .disabled(viewModel.isCapturing)
                                    .animation(.spring(response: 0.3), value: viewModel.isCapturing)
                                    .opacity(controlsOpacity)
                                    .animation(.easeInOut(duration: 0.3), value: controlsOpacity)
                                    
                                    // Camera switch button
                                    Button(action: {
                                        // Would switch camera here
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            // Rotate animation for camera switch
                                            let _ = 0 // Placeholder
                                        }
                                    }) {
                                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                                            .font(.title)
                                            .foregroundColor(.white)
                                    }
                                    .opacity(controlsOpacity)
                                    .animation(.easeInOut(duration: 0.3), value: controlsOpacity)
                                }
                                .padding(.bottom, 40)
                            }
                        }
                    }
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 1.02)),
                            removal: .opacity.combined(with: .scale(scale: 0.98))
                        )
                    )
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            cameraAppears = true
                            controlsOpacity = 1.0
                            captureButtonScale = 1.0
                        }
                    }
                } else if let capturedImage = viewModel.capturedImage {
                    // Show the captured image with animations
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    viewModel.capturedImage = nil
                                    resetAnimationState()
                                    viewModel.activateCamera()
                                }
                            }) {
                                Image(systemName: "arrow.left")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 8)
                                    .background(Circle().fill(Color.black.opacity(0.5)))
                            }
                            .padding(.leading, 20)
                            
                            Spacer()
                            
                            Text("Receipt Preview")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Color.black.opacity(0.5)))
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }) {
                                Image(systemName: "checkmark")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 8)
                                    .background(Circle().fill(Color.black.opacity(0.5)))
                            }
                            .padding(.trailing, 20)
                        }
                        .padding(.top, geometry.safeAreaInsets.top + 10)
                        .opacity(controlsOpacity)
                        .animation(.easeInOut(duration: 0.3), value: controlsOpacity)
                        
                        Spacer()
                        
                        // Image display
                        Image(uiImage: capturedImage)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                            .padding(.horizontal, 20)
                            .transition(.opacity.combined(with: .scale(scale: 1.05)))
                            .animation(.easeInOut(duration: 0.5), value: capturedImage)
                        
                        Spacer()
                        
                        // Processing indicator
                        if viewModel.isProcessingImage {
                            HStack(spacing: 15) {
                                ProgressView()
                                    .tint(.white)
                                Text("Processing receipt...")
                                    .foregroundColor(.white)
                            }
                            .padding(.vertical, 15)
                            .padding(.horizontal, 25)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.black.opacity(0.7))
                            )
                            .padding(.bottom, 30)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        } else {
                            // Action buttons
                            VStack(spacing: 15) {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        viewModel.capturedImage = nil
                                        resetAnimationState()
                                        viewModel.activateCamera()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "camera.fill")
                                        Text("Retake Photo")
                                    }
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.white.opacity(0.2))
                                    )
                                    .foregroundColor(.white)
                                }
                                
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "checkmark")
                                        Text("Use This Photo")
                                    }
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            colors: [.blue, .purple.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .shadow(color: .blue.opacity(0.4), radius: 6, x: 0, y: 4)
                                }
                            }
                            .padding(.horizontal, 25)
                            .padding(.bottom, 40)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.isProcessingImage)
                } else {
                    // Camera selection view with animations
                    VStack(spacing: 30) {
                        Spacer()
                        
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                            .opacity(selectionScreenOpacity)
                            .animation(.easeInOut(duration: 0.5), value: selectionScreenOpacity)
                        
                        Text("Receipt Capture")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .opacity(selectionScreenOpacity)
                            .animation(.easeInOut(duration: 0.5).delay(0.1), value: selectionScreenOpacity)
                        
                        Text("Take a photo of your receipt for validation")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .opacity(selectionScreenOpacity)
                            .animation(.easeInOut(duration: 0.5).delay(0.2), value: selectionScreenOpacity)
                        
                        Spacer()
                        
                        // Action buttons
                        VStack(spacing: 15) {
                            // Camera Button
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectionScreenOpacity = 0
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    resetAnimationState()
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        viewModel.activateCamera()
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: "camera.fill")
                                    Text("Take Photo")
                                }
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: .blue.opacity(0.4), radius: 6, x: 0, y: 4)
                            }
                            .opacity(selectionScreenOpacity)
                            .animation(.easeInOut(duration: 0.5).delay(0.3), value: selectionScreenOpacity)
                            .scaleEffect(viewModel.isCameraActive ? 0.95 : 1.0)
                            
                            // Photo Library Button
                            Button(action: {
                                viewModel.selectPhoto()
                            }) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle")
                                    Text("Choose from Library")
                                }
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white.opacity(0.1))
                                .foregroundColor(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(LinearGradient(
                                            colors: [.blue, .purple.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ), lineWidth: 1.5)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .opacity(selectionScreenOpacity)
                            .animation(.easeInOut(duration: 0.5).delay(0.4), value: selectionScreenOpacity)
                            
                            // Back Button
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectionScreenOpacity = 0
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                }
                            }) {
                                Text("Back")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                    .padding(.vertical, 10)
                            }
                            .padding(.top, 10)
                            .opacity(selectionScreenOpacity)
                            .animation(.easeInOut(duration: 0.5).delay(0.5), value: selectionScreenOpacity)
                        }
                        .padding(.horizontal, 25)
                        .padding(.bottom, 40)
                    }
                    .transition(.opacity)
                    .onAppear {
                        // Reset and animate in the selection screen
                        selectionScreenOpacity = 0
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                selectionScreenOpacity = 1.0
                            }
                        }
                    }
                }
                
                // Capture overlay
                if viewModel.isCapturing {
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                        .overlay(
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.5)
                        )
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.isCapturing)
                }
            }
            .sheet(isPresented: $viewModel.showImagePicker) {
                ImagePickerView(viewModel: viewModel)
            }
            .alert(isPresented: $viewModel.showErrorAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .navigationBarBackButtonHidden(true)
            .statusBar(hidden: viewModel.isCameraActive)
            .onChange(of: viewModel.shouldDismissScreen) { shouldDismiss in
                if shouldDismiss {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectionScreenOpacity = 0
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
            .onDisappear {
                viewModel.cleanup()
            }
        }
    }
    
    // Reset animation states
    private func resetAnimationState() {
        controlsOpacity = 1.0
        cameraAppears = false
        captureButtonScale = 1.0
        selectionScreenOpacity = 1.0
    }
}

struct PhotoScreenView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoScreenView()
    }
} 
