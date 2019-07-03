//
//  FileHandlerModel.swift
//  EyeV
//
//  Created by Cenk Arioz on 15.02.2019.
//  Copyright © 2019 Cenk Arioz. All rights reserved.
//

import Foundation
import Zip
import CommonCrypto

class FileHandlerModel {
    private let isDebugMode = false
    private var directory: String
    private var imageDirURL: URL
    private var imageCount: Int
    private let fileManager: FileManager
    private var zipFileURL: URL?
    
    init() {
        directory = "EyeV"
        fileManager = .default
        imageDirURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent(directory)
        imageCount = 0
        zipFileURL = nil
        
    }
    
    func save(image data: Data) {
        
        if isDebugMode { NSLog("DEBUG: FileHandler/save") }
        let fileName = "image\(imageCount)"

        do {
            if !fileManager.fileExists(atPath: imageDirURL.path) {
                try fileManager.createDirectory(at: imageDirURL, withIntermediateDirectories: false, attributes: nil)
            }
            
            let fileURL = URL(fileURLWithPath: imageDirURL.appendingPathComponent(fileName).path)
            try data.base64EncodedData().write(to: fileURL)
        } catch {
            print("DEBUG: FileHandlerModel/save: Failed to create file. Error: \(error)")
        }
        if isDebugMode { NSLog("DEBUG: File \(fileName) saved") }
        imageCount += 1
    }
    
    func getZippedImagesURL(tckn: String) -> URL? {
        if isDebugMode { NSLog("DEBUG: FileHandler/getZippedImages") }

        do {
            let imagesPath = try FileManager.default.contentsOfDirectory(atPath: imageDirURL.path)
            let imageURLs = imagesPath.map { image in URL(fileURLWithPath: imageDirURL.appendingPathComponent(image).path) }
            zipFileURL = try Zip.quickZipFiles(imageURLs, fileName: tckn)
            
            return zipFileURL
        } catch {
            print("Could not zip files. Error: \(error)")
        }

        return nil
    }
    
    func deleteFiles() {
        if isDebugMode { NSLog("DEBUG: FileHandler/deleteFiles") }

        do {
            let images = try fileManager.contentsOfDirectory(atPath: imageDirURL.path)
            let filePaths = images.map { image in imageDirURL.appendingPathComponent(image).path }

            for filePath in filePaths {
                try fileManager.removeItem(atPath: filePath)
            }

            try fileManager.removeItem(at: imageDirURL)
        } catch {
            print("Could not delete files, error: \(error)")
        }
    }
}
