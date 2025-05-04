//
//  HomeView.swift
//  ReceiptValidator
//
//  Created by Yevhenii on 5/3/25.
//

import SwiftUI

public struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.white]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Logo and App Name
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 80))
                            .foregroundStyle(LinearGradient(
                                colors: [.blue, .purple.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 5)
                            .scaleEffect(viewModel.isAnimating ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: viewModel.isAnimating)
                        
                        Text("Receipt Validator")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                    }
                    .padding(.bottom, 20)
                    
                    // Tagline
                    Text("Scan and validate receipts with ease")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                    
                    // Features list
                    VStack(alignment: .leading, spacing: 15) {
                        ForEach(viewModel.features) { feature in
                            FeatureRow(icon: feature.icon, text: feature.text)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 30)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    // Camera Button - Updated to use the new PhotoScreenView
                    NavigationLink(destination: PhotoScreenView()) {
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
                        .shadow(color: .blue.opacity(0.4), radius: 6, x: 0, y: 4)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
            .onAppear {
                viewModel.startAnimation()
            }
        }
    }
}

#Preview {
    HomeView()
} 
