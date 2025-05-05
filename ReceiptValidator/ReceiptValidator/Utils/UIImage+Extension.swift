//
//  UIImage+Extension.swift
//  ReceiptValidator
//
//  Created by Yevhenii on 5/4/25.
//

import Foundation
import UIKit

extension UIImage {
    func resize(to size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
