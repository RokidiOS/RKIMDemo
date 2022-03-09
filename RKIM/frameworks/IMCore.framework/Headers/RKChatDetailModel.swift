//
//  ChatDetailModel.swift
//  RKIM
//
//  Created by chzy on 2021/11/3.
//  聊天详情 models

import Foundation
import HandyJSON
import WCDBSwift
import RKUtils

public enum MessageContentType: String, HandyJSONEnum {
    case Text = "1"
    case Image = "2"
    case Video = "3"
    case Voice = "4"
    case File = "5"
    case system = "100"
    case Unknown = "0"
}

public enum SystemMessageType: Int, HandyJSONEnum {
    case NewGroup = 1
    case InvitGroup = 2
    case RmoveGroup = 3
    case dissolvenGroup = 4
    case LogOut = 5
}

public enum messageSateType: Int32{
    case fail = -1
    case success = 1
    case transfering = 0
}
// 消息详情
public class RKMessageDetail: NSObject, HandyJSON {
    /* 文字信息 */
    public var content: String?
    /* 图片信息 */
    public var imgUrl: String? /// 图片url
    public var thumbUrl: String? /// 图片缩略图url
    public var imgWidth: String? /// 图片宽度
    public var imgHeight: String? /// 图片高度
    /* 视频信息 */
    public var videoUrl: String? /// 视频url
    public var duration: String? /// 视频时长 or 语音时长
    public var videoWidth: String? /// 图片宽度
    public var videoHeight: String? /// 图片高度
    
    /* 语音信息 */
    public var voiceUrl: String? /// 语音url
    /* 文件信息 */
    public var fileUrl: String? /// 文件url
    public var fileSize: String? /// 文件大小
    public var localTms: String? /// 本地消息时间戳
    public var systemType:SystemMessageType?
    public func mapping(mapper: HelpingMapper) {
        mapper <<<
            systemType <-- ["actionType"]
    }
    required public override init() {}
}

public class RKChatMessage: NSObject, HandyJSON, TableCodable {
  
    public var ownerId: String = RKUserCenter.userInfo.userId
    public  var messageType: MessageContentType? ///消息类型
    public var messageDetailModel: RKMessageDetail?{
        get {
             return RKMessageDetail.deserialize(from: messageDetailJson) 
        }
    } ///消息内容
    var messageDetailJson: String? /// 消息内容json
    public var shouldShowTime = false ///是否需要显示时间
    public var sendTimeLong: Double = 0 ///消息时间戳
    public var messageID: String = ""  ///消息id
    public var sender: String = "" ///消息发送者id
    public var senderName: String = "" ///发送者name
    public var senderAvator: String = ""///发送者url
    public var messageSate: messageSateType?///消息状态
    public var reciever: String = "" ///消息接受者id
    public var receiveGroup: String = "" ///消息接受群组 receiveGroup

    public var imgName: String? ///本地图片name
    public var imgURL: String?
    
    public func imgPath() -> String {
        guard let imgName = imgName else { return " " }
        return RKIMUtil.fileDir() + "/" + imgName
    }
    
    public func mapping(mapper: HelpingMapper) {
        mapper <<<
            messageDetailJson <-- ["messageDetail"]
        mapper <<<
            messageID <-- ["id"]
    }

    public enum directionType {
        case send ///发送
        case receive ///接收
        case unknown /// 未知
    }
    
   public var direction: directionType { ///发送方向
        get {
            if reciever == sender {
                return .send
            } else {
                return .receive
            }
        }
    }
    //传输进度
    public var tranferProgress:Float = 0.0
    
    //计算消息时间的显示字符串
    public var chatTime: String {
        get {
            // 创建日历对象
            let calendar = Calendar.current
            // 获取当前时间
            let currentDate = Date()
            // 获取当前时间的年、月、日。利用日历
            var components = calendar.dateComponents([.year,.month,.day], from: currentDate)
            guard let currentYear = components.year,
                     let currentMonth = components.month,
                     let currentDay = components.day  else {
                     return ""
            }
            
            
            // 获取消息发送时间的年、月、日
            let msgDate = Date(timeIntervalSince1970: TimeInterval(sendTimeLong / 1000))
            components = calendar.dateComponents([.year,.month,.day,.hour,.weekday], from: msgDate)
            guard let msgYear = components.year,
                     let msgMonth = components.month,
                     let msgDay = components.day,
                     let msgHoure = components.hour,
                     let msgWeekday = components.weekday  else {
                     return ""
            }
            
            var preStr = ""
            let morningOrAfternoonStr = msgHoure <= 12 ? "上午 " : "下午 "
            
            if currentYear == msgYear && currentMonth == msgMonth && currentDay == msgDay {//今天
                preStr = ""
            } else if currentYear == msgYear && currentMonth == msgMonth && currentDay-1 == msgDay {//昨天
                preStr = "昨天 "
            } else if msgDate.compare(.isThisWeek) {//本周
                let weekdays = ["","星期天 ","星期一 ","星期二 ","星期三 ","星期四 ","星期五 ","星期六 ",""]
                preStr = weekdays[msgWeekday]
            } else {//其它
                preStr = "yyyy年MM月dd日 "
            }
            let dateFmt = DateFormatter()
            dateFmt.dateFormat = preStr + morningOrAfternoonStr + "hh:mm"
            return dateFmt.string(from: msgDate)
        }
    }
    
    required public override init() {}
}


