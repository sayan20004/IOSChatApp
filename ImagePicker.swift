//
//  ImagePicker.swift
//  ChatApp
//
//  Created by Sayan  Maity  on 14/08/25.
//

import UIKit

class ImagePicker: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private var pickerController: UIImagePickerController!
    private weak var presentingController: UIViewController?
    private var completion: ((UIImage?) -> Void)?
    
    override init() {
        super.init()
        pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.allowsEditing = false
        pickerController.mediaTypes = ["public.image"]
    }
    
    /// Presents the image picker
    func present(from viewController: UIViewController, completion: @escaping (UIImage?) -> Void) {
        self.presentingController = viewController
        self.completion = completion
        
        pickerController.sourceType = .photoLibrary
        viewController.present(pickerController, animated: true, completion: nil)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let image = info[.originalImage] as? UIImage
        picker.dismiss(animated: true) {
            self.completion?(image)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
            self.completion?(nil)
        }

    }
}
