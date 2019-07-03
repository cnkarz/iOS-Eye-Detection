//
//  EncryptionModel.swift
//  EyeV
//
//  Created by Cenk Arioz on 28.01.2019.
//  Copyright © 2019 Cenk Arioz. All rights reserved.
//

import Foundation
import CryptoSwift

class CryptographyModel {
    
    enum Operation {
        case encrypt
        case decrypt
    }
    
    //MARK: Properties
    private let isDebugMode: Bool
    private let aesBlockSize: Int
    private let keySizeAES128: Int
    private let key: String
    
    init() {
        isDebugMode = false
        aesBlockSize = 16
        keySizeAES128 = 16
        key = "dFAcB64D8b336573"
    }
    
    //MARK: Public Methods
    func encrypt(data: Data) -> Data {
        return crypt(data: data, operation: .encrypt)
    }
    
    func decrypt(data: Data) -> Data {
        return crypt(data: data, operation: .decrypt)
    }
    
    //MARK: Private Method
    private func crypt(data: Data, operation: Operation) -> Data {
        
        guard key.count == keySizeAES128 else {
            fatalError("Key size failed!")
        }
        var outData: Data? = nil
        
        if operation == .encrypt {
            var ivBytes = [UInt8](repeating: 0, count: aesBlockSize)
            guard 0 == SecRandomCopyBytes(kSecRandomDefault, ivBytes.count, &ivBytes) else {
                fatalError("IV creation failed!")
            }
            
            do {
                let aes = try AES(key: Array(key.data(using: .utf8)!), blockMode: CBC(iv: ivBytes))
                let encrypted = try aes.encrypt(Array(data))
                ivBytes.append(contentsOf: encrypted)
                outData = Data(bytes: ivBytes)
                
            } catch {
                print("Encryption error: \(error)")
            }
            
        } else {
            let ivBytes = Array(Array(data).dropLast(data.count - aesBlockSize))
            let inBytes = Array(Array(data).dropFirst(aesBlockSize))

            do {
                let aes = try AES(key: Array(key.data(using: .utf8)!), blockMode: CBC(iv: ivBytes))
                let decrypted = try aes.decrypt(inBytes)
                outData = Data(bytes: decrypted)
                
            } catch {
                print("Decryption error: \(error)")
            }
        }
        return outData!

    }
}
