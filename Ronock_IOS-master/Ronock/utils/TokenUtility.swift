//
//  TokenUtility.swift
//  Ronock
//
//  Created by Khaled Odat on 12/4/19.
//  Copyright © 2019 Business Intelligence For Technology. All rights reserved.
//

import Foundation

struct TokenUtility {
     typealias Context = UnsafeMutablePointer<CCHmacContext>

     static func getSasToken(forResourceUrl resourceUrl : String, withKeyName keyName : String, andKey key : String, andExpiryInSeconds expiryInSeconds : Int = 3600) -> TokenData {
         let expiry = (Int(NSDate().timeIntervalSince1970) + expiryInSeconds).description
         let encodedUrl = urlEncodedString(withString: resourceUrl)
         let stringToSign = "\(encodedUrl)\n\(expiry)"
         let hashValue = sha256HMac(withData: stringToSign.data(using: .utf8)!, andKey: key.data(using: .utf8)!)
         let signature = hashValue.base64EncodedString(options: .init(rawValue: 0))
         let encodedSignature = urlEncodedString(withString: signature)
         let sasToken = "SharedAccessSignature sr=\(encodedUrl)&sig=\(encodedSignature)&se=\(expiry)&skn=\(keyName)"
         let tokenData = TokenData(withToken: sasToken, andTokenExpiration: expiryInSeconds)

         return tokenData
     }

     private static func sha256HMac(withData data : Data, andKey key : Data) -> Data {
         let context = Context.allocate(capacity: 1)
         CCHmacInit(context, CCHmacAlgorithm(kCCHmacAlgSHA256), (key as NSData).bytes, size_t((key as NSData).length))
         CCHmacUpdate(context, (data as NSData).bytes, (data as NSData).length)
         var hmac = Array<UInt8>(repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
         CCHmacFinal(context, &hmac)

         let result = NSData(bytes: hmac, length: hmac.count)
         context.deallocate()

         return result as Data
     }

     private static func urlEncodedString(withString stringToConvert : String) -> String {
         var encodedString = ""
         let sourceUtf8 = (stringToConvert as NSString).utf8String
        let length = strlen(sourceUtf8!)

         let charArray: [Character] = [ ".", "-", "_", "~", "a", "z", "A", "Z", "0", "9"]
         let asUInt8Array = String(charArray).utf8.map{ Int8($0) }

         for i in 0..<length {
             let currentChar = sourceUtf8![i]

             if (currentChar == asUInt8Array[0] || currentChar == asUInt8Array[1] || currentChar == asUInt8Array[2] || currentChar == asUInt8Array[3] ||
                 (currentChar >= asUInt8Array[4] && currentChar <= asUInt8Array[5]) ||
                 (currentChar >= asUInt8Array[6] && currentChar <= asUInt8Array[7]) ||
                 (currentChar >= asUInt8Array[8] && currentChar <= asUInt8Array[9])) {
                 encodedString += String(format:"%c", currentChar)
             }
             else {
                 encodedString += String(format:"%%%02x", currentChar)
             }
         }

         return encodedString
     }
 }
