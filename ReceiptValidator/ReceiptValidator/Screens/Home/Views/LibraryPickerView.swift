//
//  LibraryPickerView.swift
//  ReceiptValidator
//
//  Created by Yevhenii on 5/4/25.
//

import SwiftUI
import UIKit

/// A UIViewControllerRepresentable wrapper for UIImagePickerController
/// that allows selecting images from the photo library
public struct LibraryPickerView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedImage: UIImage?
    
    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: LibraryPickerView
        
        init(_ parent: LibraryPickerView) {
            self.parent = parent
        }
        
        public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
} 