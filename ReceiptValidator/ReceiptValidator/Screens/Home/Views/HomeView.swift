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

    private struct Constants {
        // Layout
        static let logoTopPadding: CGFloat = 30
        static let horizontalPadding: CGFloat = 20
        static let buttonHorizontalPadding: CGFloat = 25
        static let buttonBottomPadding: CGFloat = 30
        static let footerBottomPadding: CGFloat = 5

        // Animation
        static let contentAnimationDuration: Double = 0.5

        // Logo
        static let logoSize: CGFloat = 100
        static let logoFontSize: CGFloat = 50
        static let logoGradientColors = [Color.blue.opacity(0.7), Color.purple.opacity(0.4)]
        static let logoShadowColor = Color.blue.opacity(0.3)
        static let logoShadowRadius: CGFloat = 8
        static let logoShadowYOffset: CGFloat = 4

        // App Name
        static let appNameFontSize: CGFloat = 30
        static let appNameGradientColors = [Color.blue, Color.purple]

        // Card
        static let cardCornerRadius: CGFloat = 15
        static let cardShadowColor = Color.black.opacity(0.1)
        static let cardShadowRadius: CGFloat = 10
        static let cardShadowYOffset: CGFloat = 5

        // Footer
        static let footerOpacity: Double = 0.8
        static let footerCopyrightText: String = "© 2025 Receipt Validator"
    }

    public init() {}

    public var body: some View {
        ZStack {
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
                        .font(.system(size: Constants.logoFontSize))
                        .foregroundColor(.primary)
                        .frame(width: Constants.logoSize, height: Constants.logoSize)
                        .background(
                            Circle()
                                .fill(LinearGradient(colors: Constants.logoGradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(color: Constants.logoShadowColor, radius: Constants.logoShadowRadius, x: 0, y: Constants.logoShadowYOffset)
                        )

                    Text("Receipt Validator")
                        .font(.system(size: Constants.appNameFontSize, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: Constants.appNameGradientColors, startPoint: .leading, endPoint: .trailing))
                }
                .padding(.top, Constants.logoTopPadding)

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
                    RoundedRectangle(cornerRadius: Constants.cardCornerRadius)
                        .fill(Color(uiColor: .secondarySystemBackground))
                        .shadow(color: Constants.cardShadowColor, radius: Constants.cardShadowRadius, x: 0, y: Constants.cardShadowYOffset)
                )
                .padding(.horizontal, Constants.horizontalPadding)

                Spacer()

                VStack(spacing: 15) {
                    Button(action: { showCamera = true }) {
                        ActionButtonView(icon: "camera.fill", text: "Take Photo", isPrimary: true)
                    }

                    Button(action: { navigateToPhotoScreen = true }) {
                        ActionButtonView(icon: "photo.on.rectangle", text: "Photo Library", isPrimary: false)
                    }
                }
                .padding(.horizontal, Constants.buttonHorizontalPadding)
                .padding(.bottom, Constants.buttonBottomPadding)
                .offset(y: buttonOffset)

                Text(Constants.footerCopyrightText)
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(Constants.footerOpacity))
                    .padding(.bottom, Constants.footerBottomPadding)
            }
            .opacity(contentOpacity)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: Constants.contentAnimationDuration)) {
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

    private struct Constants {
        static let cornerRadius: CGFloat = 12
        static let primaryGradientColors = [Color.blue, Color.purple.opacity(0.8)]
        static let secondaryBackgroundColor = Color(uiColor: .secondarySystemBackground)
        static let primaryTextColor = Color.white
        static let secondaryTextColor = Color.primary
        static let primaryShadowColor = Color.blue.opacity(0.3)
        static let secondaryShadowColor = Color.black.opacity(0.05)
        static let primaryShadowRadius: CGFloat = 4
        static let secondaryShadowRadius: CGFloat = 2
        static let primaryShadowYOffset: CGFloat = 3
        static let secondaryShadowYOffset: CGFloat = 1
        static let paddingVertical: CGFloat = 15
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
            Text(text)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Constants.paddingVertical)
        .background(
            Group {
                if isPrimary {
                    LinearGradient(
                        colors: Constants.primaryGradientColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                } else {
                    Constants.secondaryBackgroundColor
                }
            }
        )
        .foregroundColor(isPrimary ? Constants.primaryTextColor : Constants.secondaryTextColor)
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
        .overlay(
            Group {
                if !isPrimary {
                    RoundedRectangle(cornerRadius: Constants.cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: Constants.primaryGradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 2
                        )
                }
            }
        )
        .shadow(
            color: isPrimary ? Constants.primaryShadowColor : Constants.secondaryShadowColor,
            radius: isPrimary ? Constants.primaryShadowRadius : Constants.secondaryShadowRadius,
            x: 0,
            y: isPrimary ? Constants.primaryShadowYOffset : Constants.secondaryShadowYOffset
        )
    }
}
