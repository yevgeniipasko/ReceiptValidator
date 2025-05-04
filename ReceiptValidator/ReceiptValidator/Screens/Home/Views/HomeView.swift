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
    @State private var isReceiptValidationPresented = false
    
    // Animation states
    @State private var logoScale = 0.8
    @State private var featuresOpacity = 0.0
    @State private var buttonOffset: CGFloat = 100
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.15), Color.white]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Background pattern
                VStack {
                    ForEach(0..<10) { row in
                        HStack(spacing: 30) {
                            ForEach(0..<6) { col in
                                Circle()
                                    .fill(Color.blue.opacity(0.05))
                                    .frame(width: 20, height: 20)
                            }
                        }
                    }
                }
                .rotationEffect(.degrees(45))
                .offset(y: -100)
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Logo and App Name
                        VStack(spacing: 15) {
                            // Logo Icon
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue.opacity(0.7), .purple.opacity(0.4)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                                
                                Image(systemName: "doc.text.viewfinder")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                            }
                            .scaleEffect(logoScale)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: logoScale)
                            
                            // App Name
                            Text("Receipt Validator")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .padding(.top, 5)
                                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                        }
                        .padding(.top, 30)
                        
                        // Tagline
                        Text("Validate receipts with advanced AI")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.bottom, 10)
                        
                        // Features card
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Features")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                                .padding(.bottom, 5)
                            
                            ForEach(viewModel.features) { feature in
                                FeatureRowEnhanced(icon: feature.icon, text: feature.text)
                                    .padding(.vertical, 5)
                            }
                        }
                        .padding(.horizontal, 25)
                        .padding(.vertical, 30)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 8)
                        )
                        .padding(.horizontal, 20)
                        .opacity(featuresOpacity)
                        .animation(.easeInOut(duration: 0.5).delay(0.3), value: featuresOpacity)
                        
                        // Action Buttons
                        VStack(spacing: 16) {
                            // Camera Button
                            Button(action: {
                                showCamera = true
                            }) {
                                HStack(spacing: 15) {
                                    Image(systemName: "camera.fill")
                                        .font(.headline)
                                    Text("Take Photo")
                                        .font(.headline)
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
                                .shadow(color: .blue.opacity(0.5), radius: 5, x: 0, y: 3)
                            }
                            
                            // Photo Library Button
                            Button(action: {
                                navigateToPhotoScreen = true
                            }) {
                                HStack(spacing: 15) {
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.headline)
                                    Text("Photo Library")
                                        .font(.headline)
                                }
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .foregroundColor(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(LinearGradient(
                                            colors: [.blue, .purple.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ), lineWidth: 2)
                                )
                                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 10)
                        .padding(.bottom, 40)
                        .offset(y: buttonOffset)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: buttonOffset)
                        
                        // App information
                        VStack(spacing: 8) {
                            Text("© 2025 Receipt Validator")
                                .font(.caption2)
                                .foregroundColor(.gray.opacity(0.8))
                                .padding(.bottom, 10)
                                .opacity(featuresOpacity)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .onAppear {
                // Start animations when view appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation {
                        logoScale = 1.0
                        featuresOpacity = 1.0
                        buttonOffset = 0
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraCaptureView(image: $viewModel.capturedImage)
                    .environmentObject(serviceProvider.cameraService)
                    .onDisappear {
                        if viewModel.capturedImage != nil {
                            isReceiptValidationPresented = true
                        }
                    }
            }
            .fullScreenCover(isPresented: $navigateToPhotoScreen) {
                // Open the photo library (using ImagePicker) instead of PhotoScreenView
                LibraryPickerView(selectedImage: $viewModel.capturedImage)
                    .onDisappear {
                        if viewModel.capturedImage != nil {
                            isReceiptValidationPresented = true
                        }
                    }
            }
            .sheet(isPresented: $isReceiptValidationPresented) {
                if let image = viewModel.capturedImage {
                    ReceiptValidationView(image: image)
                        .environmentObject(serviceProvider.receiptValidatorService as! ReceiptValidatorService)
                }
            }
        }
    }
}

#Preview {
    HomeView()
} 
