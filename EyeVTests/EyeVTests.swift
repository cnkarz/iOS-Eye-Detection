//
//  EyeVTests.swift
//  EyeVTests
//
//  Created by Cenk Arioz on 28.01.2019.
//  Copyright © 2019 Cenk Arioz. All rights reserved.
//

import XCTest
import UIKit
@testable import EyeV

class EyeVTests: XCTestCase {
    

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testTextEncryptThenDecrypt() {
        let message = "Very secret message."
        
        let messageData = message.data(using: String.Encoding.utf8)
        let encrypted = CryptographyModel().encrypt(data: messageData!)
        let decrypted = CryptographyModel().decrypt(data: encrypted)
        let decryptedMessage = String(data: decrypted, encoding: String.Encoding.utf8)
//        print(" TEST/Decrypted message is: \(decryptedMessage)")
        XCTAssert(messageData == decrypted)
    }
    
    func testImageEncryptThenDecrypt() {
        let image = UIImage(named: "CybersoftLogo")!.jpegData(compressionQuality: 1)

//        print(" TEST/Input data is: \(image!.base64EncodedString())")
        let encrypted = CryptographyModel().encrypt(data: image!)
        let decrypted = CryptographyModel().decrypt(data: encrypted)
//        print(" TEST/Decrypted data is: \(decrypted.base64EncodedString())")
        
        XCTAssert(image == decrypted)
    }
    
//    func testSaveThenZipThenDeleteFile() {
//        let fileHandler = FileHandlerModel()
//
//        let testPath = fileHandler.imageDirURL.appendingPathComponent("image0")
//        let testData = "This is a test".data(using: .utf8)
//        
//        // Save file
//        fileHandler.save(image: testData!)
//        XCTAssert(fileHandler.fileManager.fileExists(atPath: testPath.path))
//        
//        // Zip files
//        let zippedImagesURL = fileHandler.getZippedImagesURL()
//        XCTAssert(zippedImagesURL != nil)
//
//        // Delete images and zip file
//        fileHandler.deleteFiles()
//        XCTAssert(!fileHandler.fileManager.fileExists(atPath: fileHandler.imageDirURL.path))
//        XCTAssert(!fileHandler.fileManager.fileExists(atPath: fileHandler.zipFileURL!.path))
//
//    }
    
    func testHttpGetRequest() {
        let jsonMessage = ["text": "This is a test request"]
        guard let requestMessage = try? JSONEncoder().encode(jsonMessage) else {
            return
        }
        
//        let response = HTTPConnectionModel().get(requestJson: requestMessage)
        
//        XCTAssert(response == 200)
    }
    

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
