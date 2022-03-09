//
//  VideoResLoader.swift
//  VideoDownloader
//
//  Created by chzy on 2022/2/13.
//

import Foundation
import AVFoundation


class VideoResLoader: NSObject {
    
    var assset: AVURLAsset?
    var tmpData = Data()
    func playItem(_ url: URL?) -> AVPlayerItem? {
        guard let url = url else {
            return nil
        }
        loaderManager.delegate = self
        if let info = VideoFileManager.shared.existInfo(url) {
            let (data, path) = VideoFileManager.shared.asGetVideofile(url)
            if let data = data {
                if data.count == info.contentLength {
                    assset = AVURLAsset(url: path)
                }
            }
            
        }
        if assset == nil {
//            let schemeURL = loaderManager.assetURL(url) 服务端不支持断点续传 暂时不用
//            guard let schemeURL = schemeURL else { return nil }
            let schemeURL = url
            assset = AVURLAsset(url: schemeURL)
            assset?.resourceLoader.setDelegate(self, queue: DispatchQueue.main)
        }
        if let assset = assset {
            let item = AVPlayerItem(asset: assset)
            return item
        }
        return nil
    }
    

    
    deinit {
        assset?.resourceLoader.setDelegate(nil, queue: DispatchQueue.main)
        loaderManager.cancellAllResloadRequest()
    }
    
    lazy var loaderManager: ResLoadManager = {
        let manager = ResLoadManager()
        return manager
    }()
    
}

extension VideoResLoader: ResLoadManagerDelegate {
    func fillContentInfo(info: VideoHttpHeaderInfo, loadRequest: AVAssetResourceLoadingRequest) {
        guard let contentInformationRequest = loadRequest.contentInformationRequest else { return }
        contentInformationRequest.contentType = info.contentType
        contentInformationRequest.isByteRangeAccessSupported = info.isByteRangeAccessSupported
        contentInformationRequest.contentLength = Int64(info.contentLength)
    }
    
    func didRecieve(data: Data, loadRequest: AVAssetResourceLoadingRequest) {
        loadRequest.dataRequest?.respond(with: data)
    }
    
    func complete(error: Error?, loadRequest: AVAssetResourceLoadingRequest) {
        if let error = error {
            loadRequest.finishLoading(with: error)
        } else {
            loadRequest.finishLoading()
        }
    }
     
}

extension VideoResLoader: AVAssetResourceLoaderDelegate {
   
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        loaderManager.addResloadRequest(loadingRequest)
        return true
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        loaderManager.cancelResloadRequest(loadingRequest)
    }

}


