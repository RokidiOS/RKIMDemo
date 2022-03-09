//
//  IMPhotoBrowser.swift
//  Pods
//
//  Created by chzy on 2021/11/9.
//

import Foundation
import JXPhotoBrowser
import UIKit
import Kingfisher
import RKIMCore
import CoreAudio
import AVFoundation

class IMPhotoBrowser: NSObject {
    
    static var videoLoader: VideoResLoader?
    /// 显示图片浏览器
    /// - Parameters:
    ///   - messageList: 消息列表
    ///   - message: 当前图片消息
    ///   - nowVC: 当前vc
    class func showBrowser(_ messageList: [RKIMMessage],_ message: RKIMMessage, _ nowVC: UIViewController, _ imageView: UIImageView) {
        let browser = JXPhotoBrowser()
        
        let imageArray = messageList.filter({ perMessage in
            if perMessage.messageType == .Image {
                return true
            }
            
            if perMessage.messageType == .Video {
                return true
            }
            
            return false
        })
        
        browser.numberOfItems = {
            imageArray.count
        }
        
        browser.cellClassAtIndex = {
            index in
            let message = imageArray[index]
            if message.messageType == .Video {
                return JXVideoCell.self
            }
            return JXPhotoBrowserImageCell.self
        }
        
        browser.reloadCellAtIndex = { context in
            
            let url = imageArray[context.index].messageDetailModel?.imgUrl.flatMap { URL(string: $0) }
            print(context.index)
            let message = imageArray[context.index]
            if message.messageType == .Video {

                let browserCell = context.cell as? JXVideoCell
            
                guard let videoUrl = message.messageDetailModel?.videoUrl else { return }
                guard let voiceUrl = videoUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
                guard let url = URL(string: voiceUrl) else { return }
//                guard let url = URL(string: "https://klxxcdn.oss-cn-hangzhou.aliyuncs.com/histudy/hrm/media/bg3.mp4") else { return }

                if let thumbUrl = message.messageDetailModel?.thumbUrl {
                    browserCell?.placeHolderImageView.kf.setImage(with: URL(string: thumbUrl))
                }
            
                videoLoader = VideoResLoader()
                if let item = videoLoader?.playItem(url) {
                    browserCell?.player.replaceCurrentItem(with: item)
                }
             
            } else if message.messageType == .Image {
                let browserCell = context.cell as? JXPhotoBrowserImageCell
                var placeholder: UIImage?
                if let thumbUrl = message.messageDetailModel?.thumbUrl {
                    placeholder = KingfisherManager.shared.cache.retrieveImageInDiskCache(forKey: thumbUrl, options: .none)
                }
                browserCell?.imageView.kf.setImage(with: url, placeholder: placeholder)
                
            }
        }
        
        browser.cellWillAppear = { cell, index in
            let message = imageArray[index]
            if message.messageType == .Video {
                (cell as? JXVideoCell)?.player.play()
            }
        }
        
        browser.cellWillDisappear = { cell, index in
            let message = imageArray[index]
            if message.messageType == .Video {
                (cell as? JXVideoCell)?.player.pause()
            }
        }
        
        browser.transitionAnimator = JXPhotoBrowserZoomAnimator(previousView: { index -> UIView? in
            let tableViewPath = IndexPath(item: getIndex(messageList, imageArray[index]), section: 0)
            if let nowVC = nowVC as? RKChatDetailVC {
                if let cell = nowVC.chatTableView.cellForRow(at: tableViewPath) as? RKChatImageCell {
                    return cell.photoImageView
                }
            }
            return imageView
        })
        
        browser.pageIndex = getIndex(imageArray, message)
        browser.show()
    }
    
    class func getIndex(_ messageList: [RKIMMessage], _ message:RKIMMessage) -> Int {
        guard let indx = messageList.firstIndex(where: {$0 == message}) else { return 0 }
        return indx
    }
}
