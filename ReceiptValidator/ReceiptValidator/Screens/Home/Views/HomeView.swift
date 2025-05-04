//
//  HomeView.swift
//  ReceiptValidator
//
//  Created by Yevhenii on 5/3/25.
//

import SwiftUI
import UIKit
import AVFoundation

// No need for additional imports as the views are in the same module

public struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @Environment(\.serviceProvider) private var serviceProvider
    @State private var showCamera = false
    @State private var navigateToPhotoScreen = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // Animation states
    @State private var contentOpacity = 0.0
    @State private var buttonOffset: CGFloat = 50
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.white]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 25) {
                // Logo and App Name
                VStack(spacing: 15) {
                    // Logo Icon
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .frame(width: 100, height: 100)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.7), .purple.opacity(0.4)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                    
                    // App Name
                    Text("Receipt Validator")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .padding(.top, 30)
                
                // Tagline
                Text("Validate receipts with advanced AI")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                // Features list (simplified)
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.features) { feature in
                        FeatureRowEnhanced(icon: feature.icon, text: feature.text)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 15) {
                    // Camera Button
                    Button(action: { showCamera = true }) {
                        ActionButtonView(
                            icon: "camera.fill",
                            text: "Take Photo",
                            isPrimary: true
                        )
                    }
                    
                    // Photo Library Button
                    Button(action: { navigateToPhotoScreen = true }) {
                        ActionButtonView(
                            icon: "photo.on.rectangle",
                            text: "Photo Library",
                            isPrimary: false
                        )
                    }
                }
                .padding(.horizontal, 25)
                .padding(.bottom, 30)
                .offset(y: buttonOffset)
                
                // Footer
                Text("© 2025 Receipt Validator")
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.8))
                    .padding(.bottom, 5)
            }
            .opacity(contentOpacity)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                contentOpacity = 1.0
                buttonOffset = 0
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView(image: $viewModel.capturedImage)
                .environmentObject(serviceProvider.cameraService)
                .onDisappear {
                    if viewModel.capturedImage != nil {
                        validateReceipt()
                    }
                }
        }
        .fullScreenCover(isPresented: $navigateToPhotoScreen) {
            LibraryPickerView(selectedImage: $viewModel.capturedImage)
                .onDisappear {
                    if viewModel.capturedImage != nil {
                        validateReceipt()
                    }
                }
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    viewModel.capturedImage = nil
                }
            )
        }
    }
    
    private func validateReceipt() {
        guard let image = viewModel.capturedImage else { return }
        
        alertTitle = "Validating..."
        alertMessage = "Please wait while we check your receipt."
        showingAlert = true
        
        serviceProvider.receiptValidatorService.validateReceipt(image: image) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let validationResult):
                    alertTitle = validationResult.isReceipt ? "Receipt Detected" : "Not a Receipt"
                    alertMessage = validationResult.isReceipt 
                        ? "This appears to be a valid receipt with \(Int(validationResult.confidence * 100))% confidence."
                        : "This image doesn't appear to be a receipt."
                case .failure(let error):
                    alertTitle = "Error"
                    alertMessage = "Failed to validate: \(error.localizedDescription)"
                }
                showingAlert = true
            }
        }
    }
}

// Helper view for action buttons
struct ActionButtonView: View {
    let icon: String
    let text: String
    let isPrimary: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
            Text(text)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(
            isPrimary ?
            LinearGradient(
                colors: [.blue, .purple.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            ) :
            LinearGradient(
                colors: [.white, .white],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .foregroundColor(isPrimary ? .white : .blue)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            if !isPrimary {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(LinearGradient(
                        colors: [.blue, .purple.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ), lineWidth: 2)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.clear, lineWidth: 0)
            }
        }
        .shadow(color: isPrimary ? .blue.opacity(0.3) : .black.opacity(0.05),
                radius: isPrimary ? 4 : 2, 
                x: 0, 
                y: isPrimary ? 3 : 1)
    }
}

#Preview {
    HomeView()
} 
