//
//  ImageProcessorModel.swift
//  EyeV
//
//  Created by Cenk Arioz on 20.02.2019.
//  Copyright © 2019 Cenk Arioz. All rights reserved.
//

import Foundation
import UIKit
import CoreImage

enum InstructionMessage {
    case placeFace
    case bringCloser
    case success
    case multipleFaces
    case eyesClosed
    case eyesOutsideCircles
}

class ImageProcessorModel {

    private let isDebugMode: Bool
    private let cryptography: CryptographyModel

    private let DESIRED_WIDTH: CGFloat
    private let ASPECT_RATIO: CGFloat
    
    init() {
        isDebugMode = false
        cryptography = CryptographyModel()
        DESIRED_WIDTH = CGFloat(296)
        ASPECT_RATIO = CGFloat(134) / CGFloat(296)
    }

    // Inspect captured photo with face recognition rules and detect eyes
    func storeOrRejectImage(image: UIImage, mainView: UIView, circleView: EyeCircleView, fileHandler: FileHandlerModel) -> InstructionMessage {
        
        let detectorOptions: [String: Any] = [CIDetectorEyeBlink: true,
                                              CIDetectorImageOrientation:
                                                CGImagePropertyOrientation.leftMirrored.rawValue,
                                              CIDetectorReturnSubFeatures: true]
        
        let ciPhoto = CIImage(cgImage: image.cgImage!)
        
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        
        let faces = faceDetector?.features(in: ciPhoto, options: detectorOptions)
        
        if let face = faces!.first as? CIFaceFeature {
            
            let width = UIScreen.main.bounds.width
            let eyeDistance = face.leftEyePosition.y - face.rightEyePosition.y
            
            if faces!.count > 1 {
                return .multipleFaces
            } else if face.leftEyeClosed || face.rightEyeClosed {
                return .eyesClosed
            } else if eyeDistance / width < 0.9 {
                return .bringCloser
            } else if !eyesMatchCircles(face: face, image: image, view: mainView, eyeCircleView: circleView) {
                return .eyesOutsideCircles
            } else {
                
                let offset = (face.leftEyePosition.y - face.rightEyePosition.y) / 3
                let width = (face.leftEyePosition.y - face.rightEyePosition.y) + 2 * offset
                let height = width * ASPECT_RATIO
                
                let eyeRect = CGRect(x: face.rightEyePosition.y - offset,
                                     y: face.rightEyePosition.x - height*2/3,
                                     width: width,
                                     height: height)
                
                let croppedResizedImage = getCroppedImageData(image: image, rect: eyeRect)
                let croppedImageData = croppedResizedImage.jpegData(compressionQuality: 1)!
                let encryptedImage = cryptography.encrypt(data: croppedImageData)
                fileHandler.save(image: encryptedImage)
                
                return .success
                
            }
        } else {
            return .placeFace
        }
    }
    
    private func eyesMatchCircles (face: CIFaceFeature, image: UIImage, view: UIView, eyeCircleView: EyeCircleView) -> Bool {
        
        let imageWidth = image.size.width
        let widthMultiplier = imageWidth / view.frame.width
        let diameterPxl = imageWidth / eyeCircleView.widthToDiameter
        
        // Set margin between two circles
        
        let minLeftEyeX = eyeCircleView.circleMargin * widthMultiplier
        let maxLeftEyeX = minLeftEyeX + diameterPxl
        let minRightEyeX = maxLeftEyeX + eyeCircleView.distanceBetweenCircles * widthMultiplier
        let maxRightEyeX = minRightEyeX + diameterPxl
        
        let minEyeY = eyeCircleView.frame.midY * (image.size.height / view.frame.height) - (diameterPxl / 2)
        let maxEyeY = minEyeY + diameterPxl
        
        if face.leftEyePosition.y < minRightEyeX || face.leftEyePosition.y > maxRightEyeX ||
            face.rightEyePosition.y < minLeftEyeX || face.rightEyePosition.y > maxLeftEyeX ||
            face.leftEyePosition.x < minEyeY || face.leftEyePosition.x > maxEyeY ||
            face.rightEyePosition.x < minEyeY || face.rightEyePosition.x > maxEyeY {
            if self.isDebugMode { NSLog("DEBUG: Photo rejected: eyes outside circles") }
            
            return false
        }
        
        if face.rightEyePosition.y / (imageWidth - face.leftEyePosition.y) < 0.95 ||
            face.rightEyePosition.y / (imageWidth - face.leftEyePosition.y) > 1.05 {
            if self.isDebugMode { NSLog("DEBUG: Photo rejected: eyes asymmetrical") }
            
            return false
        }
        return true
        
    }
    
    // Display captured and cropped photo if it passes face recognition rules
    private func getCroppedImageData(image:UIImage, rect: CGRect) -> UIImage {
        if isDebugMode { NSLog("DEBUG: Cropping photo") }
        
        let croppedCgImage = image.cgImage?.cropping(to: CGRect(x: rect.minY, y: rect.minX, width: rect.height, height: rect.width))
        
        let croppedUIImage = UIImage(cgImage: croppedCgImage!, scale: 1, orientation: image.imageOrientation)
        
        let scale = CGFloat(croppedCgImage!.width) / DESIRED_WIDTH
        let resizedUIImage = getResizedImage(image: croppedUIImage, targetSize: CGSize(width: CGFloat(croppedUIImage.cgImage!.width) / scale, height: CGFloat(croppedUIImage.cgImage!.height) / scale))
        
        //        // Check image size
        //        let bcf = ByteCountFormatter()
        //        bcf.allowedUnits = [.useKB] // optional: restricts the units to MB only
        //        bcf.countStyle = .file
        //        let string = bcf.string(fromByteCount: Int64(UIImageJPEGRepresentation(resizedUIImage, 1)!.count))
        //        print (string)
        
        return resizedUIImage
    }
    
    private func getResizedImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Detect orientation
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Draw inside new rect
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
}
