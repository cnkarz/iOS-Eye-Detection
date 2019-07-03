//
//  HTTPConnectionModel.swift
//  EyeV
//
//  Created by Cenk Arioz on 14.02.2019.
//  Copyright © 2019 Cenk Arioz. All rights reserved.
//

import Foundation

enum ServerResponse {
    case success
    case fail
}

class HTTPConnectionModel: NSObject, URLSessionDelegate {
    
    let isDebugMode = false
    let httpStatusCodes = [201, 202, 401]

    func post(url: URL, zipFile fileURL: URL, completion: @escaping (ServerResponse?) -> ()) {
        if isDebugMode { NSLog("DEBUG: HTTPConn/post") }

        let fileName = fileURL.absoluteString.split(separator: "/").last?.split(separator: ".").first!
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.allowsCellularAccess = true
        urlRequest.addValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("filename=\(fileName!).zip", forHTTPHeaderField: "Content-Disposition")
        
        var zipFile = Data(count: 0)
        do {
            zipFile = try Data(contentsOf: fileURL)
        } catch {
            print("Could not locate zip file to post")
        }

        urlRequest.addValue("\(zipFile.count)", forHTTPHeaderField: "Content-Length")

        let task = URLSession.shared.uploadTask(with: urlRequest, from: zipFile) { data, response, error in
            if let error = error {
                print ("Error: \(error)")
                return
            }
            guard let response = response as? HTTPURLResponse,
//                (200...299).contains(response.statusCode) else {
                self.httpStatusCodes.contains(response.statusCode) else {
                    print ("Server error: \(String(describing: error))")
                    return
            }
            
            guard let responseData = data else {
                print("Response does not contain any data")
                return
            }
            
            if let mimeType = response.mimeType,
                mimeType == "application/json" {
                
                if self.isDebugMode { NSLog("DEBUG: HTTPConn/post completion status code: \(response.statusCode)") }

                do {
                    let jsonDict = try JSONSerialization.jsonObject(with: responseData, options:[]) as? Dictionary<String,Any>
                    if self.isDebugMode { NSLog("DEBUG: HTTPConn/post completion json message: \(String(describing: jsonDict!["message"]))") }

                    let response = self.postResponse(json: jsonDict!)
                    completion(response)
                
                } catch {
                    print("JSON response could not be created. Error: \(error)")
                }
            }
        }

        task.resume()
    }
    
    private func postResponse(json: Dictionary<String, Any>) -> ServerResponse? {
        if isDebugMode { NSLog("DEBUG: HTTPConn/postResponse") }
        
//        Server response codes:
//        SIGN_UP_SUCCESS : 2
//        SIGN_UP_FAIL: 3
//        LOG_IN_SUCCESS: 6
//        LOG_IN_FAIL: 7
//        USER_NOT_AUTHENTICATED: 8
//        USER_NOT_FOUND: 9

        switch json["responseCode"] as? Int {
        case 3, 7, 8, 9:
            return .fail
        case 2, 6:
            return .success
        default:
            return nil
        }
    }
    
    //    Function to test connection between server and app
    //    func get() {
    //        if isDebugMode { NSLog("DEBUG: HTTPConn/get") }
    //
    //        let urlRequest = URLRequest(url: url!)
    //        let task = URLSession.shared.dataTask(with: urlRequest){data, response, error in
    //            if let error = error {
    //                print ("error: \(error)")
    //                return
    //            }
    //            guard let response = response as? HTTPURLResponse,
    //                (200...299).contains(response.statusCode) else {
    //                    print ("server error")
    //                    return
    //            }
    //            if let mimeType = response.mimeType,
    //                mimeType == "application/json",
    //                let data = data,
    //                let dataString = String(data: data, encoding: .utf8) {
    //                print ("got data: \(dataString)")
    //            }
    //        }
    //
    //        task.resume()
    //        let response = task.response as? HTTPURLResponse
    //
    //        print("GET status code is \(response?.statusCode)")
    //    }
}
