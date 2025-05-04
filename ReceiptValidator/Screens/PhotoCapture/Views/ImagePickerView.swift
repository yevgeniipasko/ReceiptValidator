//
//  ImagePickerView.swift
//  ReceiptValidator
//
//  Created by Yevhenii on 5/3/25.
//

import SwiftUI
import UIKit

// UIViewControllerRepresentable to wrap UIImagePickerController for SwiftUI
public struct ImagePickerView: UIViewControllerRepresentable {
    public typealias UIViewControllerType = UIImagePickerController
    
    @ObservedObject var viewModel: PhotoViewModel
    
    public init(viewModel: PhotoViewModel) {
        self.viewModel = viewModel
    }
    
    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = viewModel.makeImagePicker()
        picker.delegate = context.coordinator
        return picker
    }
    
    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // Nothing to update
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView
        
        public init(_ parent: ImagePickerView) {
            self.parent = parent
        }
        
        public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.viewModel.imagePickerController(picker, didFinishPickingMediaWithInfo: info)
        }
        
        public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.viewModel.imagePickerControllerDidCancel(picker)
        }
    }
} 
