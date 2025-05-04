//
//  ContentView.swift
//  ReceiptValidator
//
//  Created by Yevhenii on 5/4/25.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    // Access service provider from environment
    @Environment(\.serviceProvider) private var serviceProvider
    
    // State for captured image and validation result
    @State private var capturedImage: UIImage?
    @State private var validationResult: ReceiptValidationResult?
    @State private var isValidating = false
    @State private var showCamera = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack {
                if let capturedImage = capturedImage {
                    Image(uiImage: capturedImage)
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
                                    // Show receipt bounding box if validated as receipt
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
                                    }
                                }
                            }
                        )
                } else {
                    // Placeholder when no image
                    Image(systemName: "doc.text.viewfinder")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .foregroundColor(.gray)
                        .padding()
                }
                
                // Show validation result if available
                if let validationResult = validationResult {
                    if validationResult.isReceipt {
                        Text("✅ Receipt detected")
                            .font(.headline)
                            .foregroundColor(.green)
                        Text("Confidence: \(Int(validationResult.confidence * 100))%")
                            .font(.subheadline)
                    } else {
                        Text("❌ No receipt detected")
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 20) {
                    Button(action: {
                        showCamera = true
                    }) {
                        Label("Take Photo", systemImage: "camera")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    if let image = capturedImage {
                        Button(action: validateImage) {
                            Label(isValidating ? "Validating..." : "Validate Receipt", 
                                  systemImage: "doc.text.magnifyingglass")
                                .padding()
                                .background(isValidating ? Color.gray : Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(isValidating)
                    }
                }
                .padding()
            }
            .navigationTitle("Receipt Validator")
            .fullScreenCover(isPresented: $showCamera) {
                CameraCaptureView(image: $capturedImage)
            }
        }
    }
    
    // Validate the captured image
    private func validateImage() {
        guard let image = capturedImage else { return }
        
        isValidating = true
        errorMessage = nil
        
        // Use the receipt validator service
        serviceProvider.receiptValidatorService.validateReceipt(image: image) { result in
            DispatchQueue.main.async {
                isValidating = false
                
                switch result {
                case .success(let validationResult):
                    self.validationResult = validationResult
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    ContentView()
} 
