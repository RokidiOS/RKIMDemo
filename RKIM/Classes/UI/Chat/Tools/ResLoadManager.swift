//
//  ResLoadManager.swift
//  VideoDownloader
//
//  Created by chzy on 2022/2/14.
//

import Foundation
import AVFoundation

protocol ResLoadManagerDelegate: NSObjectProtocol {
    func fillContentInfo(info: VideoHttpHeaderInfo, loadRequest: AVAssetResourceLoadingRequest)
    
    func didRecieve(data: Data, loadRequest: AVAssetResourceLoadingRequest)
    
    func complete(error: Error?, loadRequest: AVAssetResourceLoadingRequest)
}

struct VideoHttpHeaderInfo {
    var contentType: String?
    var isByteRangeAccessSupported: Bool
    var contentLength: Int
    
    func dict() -> [String: Any?] {
        let dict: [String: Any?] = ["contentType": contentType,
                    "isByteRangeAccessSupported": isByteRangeAccessSupported,
                    "contentLength":contentLength]
        return dict
    }
    
    init(_ dict: [String: Any?]) {
        self.isByteRangeAccessSupported = true
        if let tpcontentType = dict["contentType"] as? String? {
            self.contentType = tpcontentType
        } else {
            self.contentType = ""
        }
        if let tpcontentLength = dict["contentLength"] as? Int {
            self.contentLength = tpcontentLength
        } else {
            self.contentLength = 0
        }
    }
    
    init(contentType: String?, isByteRangeAccessSupported:Bool, contentLength: Int) {
        self.contentType = contentType
        self.isByteRangeAccessSupported = isByteRangeAccessSupported
        self.contentLength = contentLength
    }
}

class ResLoadManager: NSObject {
    
    private let KScheme = "KScheme__"
    weak var delegate: ResLoadManagerDelegate?
    var isRunning = false
    var loadRequestArray = [AVAssetResourceLoadingRequest]()
    var taskDict = [AVAssetResourceLoadingRequest: URLSessionDataTask]()
    var buffData = Data()
    var totalData = Data()
    /// 开始下载
    private func beginDownload() {
        if isRunning { return }
        if let req = loadRequestArray.first {
            if !req.isFinished {
                // 开始task
                let task = creatTask(req)
                guard let task = task else { return
                    
                }
                taskDict[req] = task
                buffData = Data()
                task.resume()
                isRunning = true
            }
        }
    }
    
    private func creatTask(_ loadingReq: AVAssetResourceLoadingRequest) -> URLSessionDataTask? {
        guard let httpRange = loadingReq.rangeHeader() else { return  nil}
        print(httpRange)
        guard let url = loadingReq.request.url else { return nil }
        guard let url = originURL(url) else { return nil }
        var request = URLRequest(url: url)
        request.setValue(httpRange, forHTTPHeaderField: "Range")
        let task = session.dataTask(with: request)
        return task
    }
    
    func addResloadRequest(_ req: AVAssetResourceLoadingRequest) {
        loadRequestArray.append(req)
        beginDownload()
    }
    
    func cancelResloadRequest(_ req: AVAssetResourceLoadingRequest) {
        if let task = taskDict[req] {
            task.cancel()
            taskDict.removeValue(forKey: req)
        }
    }
    
    func cancellAllResloadRequest() {
        for task in taskDict.values {
            task.cancel()
        }
        taskDict.removeAll()
        loadRequestArray.removeAll()
    }
    
    func assetURL(_ url: URL) -> URL? {
        let urlStr = KScheme + url.absoluteString
        return URL(string: urlStr)
    }
    
    func originURL(_ url: URL) -> URL? {
        let urlStr = url.absoluteString.replacingOccurrences(of: KScheme, with: "")
        return URL(string: urlStr)
    }
    
    lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        return session
    }()
    
    func hasUp(_ url: URL, compelet:@escaping (VideoHttpHeaderInfo?) -> Void) ->Bool {
        let info = VideoFileManager.shared.existInfo(url)
        if let info = info {
            compelet(info)
            return true
        }
        compelet(nil)
        return false
    }
}

extension ResLoadManager: URLSessionDelegate, URLSessionDataDelegate {
    // 开始接受数据
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let response = response as? HTTPURLResponse {
            var isByteRangeAccessSupported = false
            if let acceptRange = response.allHeaderFields["Accept-Ranges"] as? String {
                 isByteRangeAccessSupported = acceptRange == "bytes"
            }
            var content = 0
            if let contentRange = response.allHeaderFields["Content-Range"] as? String{
                if let contentStr = contentRange.split(separator: "/").last {
                    if let tpContent = Int(contentStr) {
                        content = tpContent
                    }
                }
            }
            
            if content == 0 {
                if let contentLenght = response.allHeaderFields["Content-Length"] as? String{
                    if let tpContent = Int(contentLenght) {
                        content = tpContent
                    }
                }
            }
            
            let info = VideoHttpHeaderInfo(contentType: nil, isByteRangeAccessSupported: isByteRangeAccessSupported, contentLength: content)
            if let req = loadRequestArray.first {
                guard let url = req.request.url else { return }
//                if !hasUp(req.request.url!, compelet: { _ in }) {
                    print("***contentLength :\(info.contentLength)")
                    delegate?.fillContentInfo(info: info, loadRequest: req)
                    let data = try? JSONSerialization.data(withJSONObject: info.dict(), options: .fragmentsAllowed)
                    guard let data = data else { return }
                    VideoFileManager.shared.saveInfo(url, data: data)
//                }
            }
       
        }

        completionHandler(URLSession.ResponseDisposition.allow)
    }

 
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let req = loadRequestArray.first {
            buffData.append(data)
            delegate?.didRecieve(data: data, loadRequest: req)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let req = loadRequestArray.first {
            delegate?.complete(error: error, loadRequest: req)
            if let (low, _) = req.range() {
                    // buffData(low, upper)
                if totalData.count > low {
                    totalData.removeSubrange(low...totalData.count-1)
                }
                totalData.append(buffData)
                guard let url = task.currentRequest?.url else { return }
                print(buffData.count)
                //异步保存到手机内
                DispatchQueue.global().async {
                    VideoFileManager.shared.saveFile(url, data: self.totalData)
                }
            }
        }
        if !loadRequestArray.isEmpty {
            loadRequestArray.remove(at: 0)
        }
        
        isRunning = false
        beginDownload()
        
    }
    
    // 证书信任
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        var card: URLCredential? = nil
        if let serverTrust = challenge.protectionSpace.serverTrust {
            card = URLCredential(trust: serverTrust)
        }
        completionHandler(URLSession.AuthChallengeDisposition.useCredential, card)
    }
    

}
