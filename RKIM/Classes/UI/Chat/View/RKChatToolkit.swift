//
//  RKChatToolkit.swift
//  juphoon Duo
//
//  Created by lqq on 2019/11/7.
//  Copyright © 2019 juphoon. All rights reserved.
//

import UIKit
import AVKit
import RKUtils

class RKChatToolkit: NSObject {
    class func getNavi() -> UINavigationController? {
        let rootVC = UIApplication.shared.keyWindow?.rootViewController
        
        if let navi = rootVC as? UINavigationController {
            return navi
        }

        if let tabVC = rootVC as? UITabBarController, let navi = tabVC.viewControllers?[tabVC.selectedIndex] as? UINavigationController {
            
            return navi
        }
        
        return nil
    }
    
    class func getVideoImage(videoUrl: URL) -> UIImage {

        let avAsset = AVAsset.init(url: videoUrl)
        let generator = AVAssetImageGenerator.init(asset: avAsset)
        generator.appliesPreferredTrackTransform = true
        let time: CMTime = CMTimeMakeWithSeconds(0.0, preferredTimescale: 600) // 取第0秒， 一秒600帧
        var actualTime: CMTime = CMTimeMake(value: 0, timescale: 0)
        let cgImage: CGImage = try! generator.copyCGImage(at: time, actualTime: &actualTime)
        
        return UIImage.init(cgImage: cgImage)
    }
    
    // MARK: 字典转字符串
    class func dicValueString(_ dic: Any) -> String?{
            let data = try? JSONSerialization.data(withJSONObject: dic, options: [])
            let str = String(data: data!, encoding: String.Encoding.utf8)
            return str
        }

    // MARK: 字符串转字典
    class func stringValueDic(_ str: String) -> [String : Any]?{
            let data = str.data(using: String.Encoding.utf8)
            if let dict = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String : Any] {
                return dict
            }
            return nil
    }
    
    //时间转换
    class func formatCallDate(date: Date) -> String {
        //今天
        let isToday = date.compare(.isToday)
        if isToday {
            return date.toString(format: .custom("HH:mm"))
        }
        
        if date.compare(.isYesterday) {
            return "昨天"
        }
        
        //上周
        let cal = Calendar.current
        let compontents = cal.dateComponents([.era,.year,.month,.day,.weekday], from: date)
        let isThisWeek = date.compare(.isThisWeek)
        let isLastWeek = date.compare(.isLastWeek)
        if (isThisWeek || isLastWeek) {
            let weekdays = ["","星期天","星期一","星期二","星期三","星期四","星期五","星期六",""]
            return weekdays[compontents.weekday ?? 0]
        }
        //其它时间
        return date.toString(format: .custom("yyyy-MM-dd"))
    }
    
    //消息时间转换
    class func formatMessageDate(date: Date) -> String {
        //今天
        let isToday = date.compare(.isToday)
        if isToday {
            return date.toString(format: .custom("HH:mm"))
        }
        
        if date.compare(.isYesterday) {
            return "昨天" + date.toString(format: .custom("HH:mm"))
        }
        
        //上周
        let cal = Calendar.current
        let compontents = cal.dateComponents([.era,.year,.month,.day,.weekday], from: date)
        let isThisWeek = date.compare(.isThisWeek)
        let isLastWeek = date.compare(.isLastWeek)
        if (isThisWeek || isLastWeek) {
            let weekdays = ["","星期天","星期一","星期二","星期三","星期四","星期五","星期六",""]
            return weekdays[compontents.weekday ?? 0] + date.toString(format: .custom("HH:mm"))
        }
        //其它时间
        return date.toString(format: .custom("yyyy-MM-dd ")) + date.toString(format: .custom("HH:mm"))
    }
    
    //string转url
    class func formateUrl(urlString: String) -> URL? {
        
        var urlString = urlString
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        
        if let match = detector.firstMatch(in: urlString, options: [], range: NSRange(location: 0, length: urlString.count)) {
            // it is a link, if the match covers the whole string
            let valid = match.range.length == urlString.count
            
            if valid {
                if urlString.hasPrefix("http://") {
                    return URL(string: urlString)
                } else if urlString.hasPrefix("https://"){
                    return URL(string: urlString)
                } else {
                    urlString = "https://" + urlString
                    return URL(string: urlString)
                }
               
            }
            return nil
            
        } else {
            return nil
        }
    }

}

