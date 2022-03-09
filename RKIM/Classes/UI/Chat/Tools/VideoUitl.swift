//
//  PlayUitl.swift
//  VideoDownloader
//
//  Created by chzy on 2022/2/13.
//

import Foundation
import CommonCrypto
import AVFoundation

extension URL {
    
    func withScheme(_ scheme: String) -> URL? {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return nil
        }
        components.scheme = scheme
        return components.url
    }
    
    func videoDir() -> String {
        let videoName = md5(lastPathComponent)
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let docDir  = paths.first!
        let videoDir = docDir + "/\(videoName)"
        return videoDir
    }
    
    
    func md5(_ str:String) ->String{
        let utf8 = str.cString(using: .utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5(utf8, CC_LONG(utf8!.count - 1), &digest)
        return digest.reduce("") { $0 + String(format:"%02X", $1) }
    }
      
}


extension AVAssetResourceLoadingRequest {
    
    func rangeHeader() ->String? {
        if let (low, uper) = range() {
            return  "bytes=\(low)-\(uper)"
        }
        return nil
    }
    
    func range() -> (Int, Int)? {
        if let dataRequest = dataRequest {
            let lowerBound = Int(dataRequest.requestedOffset)
            let upperBound = lowerBound + Int(dataRequest.requestedLength) - 1
            print("*********uper***********\(upperBound)")
            return (lowerBound, upperBound)
        }
        return nil
    }
    
}


//extension URLResponse {
//
//    var sz_expectedContentLength: Int64 {
//        guard let response = self as? HTTPURLResponse else {
//            return expectedContentLength
//        }
//
//        let contentRangeKeys: [String] = [
//            "Content-Range",
//            "content-range",
//            "Content-range",
//            "content-Range",
//        ]
//        var rangeString: String?
//        for key in contentRangeKeys {
//            if let value = response.allHeaderFields[key] as? String {
//                rangeString = value
//                break
//            }
//        }
//
//        if let rangeString = rangeString,
//            let bytesString = rangeString.split(separator: "/").map({String($0)}).last,
//            let bytes = Int64(bytesString)
//        {
//            return bytes
//        } else {
//            return expectedContentLength
//        }
//    }
//
//    var sz_isByteRangeAccessSupported: Bool {
//        guard let response = self as? HTTPURLResponse else {
//            return false
//        }
//
//        let rangeAccessKeys: [String] = [
//            "Accept-Ranges",
//            "accept-ranges",
//            "Accept-ranges",
//            "accept-Ranges",
//        ]
//
//        for key in rangeAccessKeys {
//            if let value = response.allHeaderFields[key] as? String,
//                value == "bytes"
//            {
//                return true
//            }
//        }
//
//        return false
//    }
//
//}
