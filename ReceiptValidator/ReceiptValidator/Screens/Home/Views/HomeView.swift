
//
//  HomeView.swift
//  ReceiptValidator
//

import SwiftUI
import UIKit
import AVFoundation

public struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @Environment(\.serviceProvider) private var serviceProvider
    @State private var showCamera = false
    @State private var navigateToPhotoScreen = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    @State private var contentOpacity = 0.0
    @State private var buttonOffset: CGFloat = 50

    public init() {}

    public var body: some View {
        ZStack {
            // Adaptive background for dark and light mode
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(uiColor: .systemBackground),
                    Color(uiColor: .secondarySystemBackground)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 25) {
                VStack(spacing: 15) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 50))
                        .foregroundColor(.primary)
                        .frame(width: 100, height: 100)
                        .background(
                            Circle()
                                .fill(LinearGradient(colors: [.blue.opacity(0.7), .purple.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        )

                    Text("Receipt Validator")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                }
                .padding(.top, 30)

                Text("Validate receipts with advanced AI")
                    .font(.headline)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.features) { feature in
                        FeatureRowEnhanced(icon: feature.icon, text: feature.text)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(uiColor: .secondarySystemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal, 20)

                Spacer()

                VStack(spacing: 15) {
                    Button(action: { showCamera = true }) {
                        ActionButtonView(icon: "camera.fill", text: "Take Photo", isPrimary: true)
                    }

                    Button(action: { navigateToPhotoScreen = true }) {
                        ActionButtonView(icon: "photo.on.rectangle", text: "Photo Library", isPrimary: false)
                    }
                }
                .padding(.horizontal, 25)
                .padding(.bottom, 30)
                .offset(y: buttonOffset)

                Text("© 2025 Receipt Validator")
                    .font(.caption2)
                    .foregroundColor(.secondary)
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
                .onDisappear {
                    if viewModel.capturedImage != nil {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            validateReceipt()
                        }
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
            Group {
                if isPrimary {
                    LinearGradient(
                        colors: [.blue, .purple.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                } else {
                    Color(uiColor: .secondarySystemBackground)
                }
            }
        )
        .foregroundColor(isPrimary ? .white : .primary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            Group {
                if !isPrimary {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 2
                        )
                }
            }
        )
        .shadow(
            color: isPrimary ? .blue.opacity(0.3) : .black.opacity(0.05),
            radius: isPrimary ? 4 : 2,
            x: 0,
            y: isPrimary ? 3 : 1
        )
    }
}
