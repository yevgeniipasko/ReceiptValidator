//
//  ReceiptValidationView.swift
//  ReceiptValidator
//
//  Created by Yevhenii on 5/4/25.
//

import SwiftUI

/// A view to display receipt validation results
public struct ReceiptValidationView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var receiptValidatorService: ReceiptValidatorService
    
    let image: UIImage
    @State private var validationResult: ReceiptValidationResult?
    @State private var isValidating = true
    @State private var errorMessage: String?
    
    public var body: some View {
        NavigationView {
            VStack {
                // Image with overlay
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding()
                    .overlay(
                        Group {
                            if let validationResult = validationResult,
                               let boundingBox = validationResult.boundingBox,
                               validationResult.isReceipt {
                                GeometryReader { geo in
                                    let rect = CGRect(
                                        x: geo.size.width * boundingBox.minX,
                                        y: geo.size.height * boundingBox.minY,
                                        width: geo.size.width * boundingBox.width,
                                        height: geo.size.height * boundingBox.height
                                    )
                                    
                                    Rectangle()
                                        .path(in: rect)
                                        .stroke(Color.green, lineWidth: 3)
                                        .animation(.easeInOut, value: validationResult.isReceipt)
                                }
                            }
                        }
                    )
                
                // Result display
                if isValidating {
                    VStack(spacing: 15) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.5)
                        
                        Text("Validating receipt...")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 20)
                } else if let validationResult = validationResult {
                    VStack(spacing: 15) {
                        // Success or failure icon
                        Image(systemName: validationResult.isReceipt ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(validationResult.isReceipt ? .green : .red)
                            .shadow(color: validationResult.isReceipt ? .green.opacity(0.3) : .red.opacity(0.3), radius: 5)
                        
                        // Status text
                        Text(validationResult.isReceipt ? "Receipt Detected" : "Not a Receipt")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(validationResult.isReceipt ? .green : .red)
                        
                        if validationResult.isReceipt {
                            Text("Confidence: \(Int(validationResult.confidence * 100))%")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.top, 5)
                        }
                    }
                    .padding(.top, 20)
                    .transition(.opacity)
                    .animation(.easeInOut, value: isValidating)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Error")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    .padding(.top, 20)
                }
                
                Spacer()
                
                // Action button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text(isValidating ? "Cancel" : "Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isValidating ? Color.gray : Color.blue)
                        )
                    .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("Receipt Validation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .onAppear {
                validateImage()
            }
        }
    }
    
    private func validateImage() {
        isValidating = true
        errorMessage = nil
        
        receiptValidatorService.validateReceipt(image: image) { result in
            DispatchQueue.main.async {
                isValidating = false
                
                switch result {
                case .success(let validationResult):
                    self.validationResult = validationResult
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
} 
