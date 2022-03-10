//
//  ChatListCell.swift
//  Alamofire
//
//  Created by chzy on 2021/11/2.
//

import Foundation
import RKIBaseView
import RKIHandyJSON
import Kingfisher
import RKIMCore

class RKChatListCell: RKBaseCell {
    
    //头像
    private lazy var avatarImageView = UIImageView().then {
        bgView.addSubview($0)
        $0.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.top.equalTo(12)
            make.size.equalTo(CGSize(width: 48, height: 48))
            make.bottom.equalTo(-12)
        }
                
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
//        $0.image = UIImage(named: "groupHead", classObject: self)
    }
    
    //未读消息背景view 宽度通过约束label去撑开
    private lazy var unreadView = UIView().then {
        bgView.addSubview($0)
        $0.snp.makeConstraints { make in
            make.height.equalTo(18)
            make.width.greaterThanOrEqualTo(18) //最小宽度
            make.centerY.equalTo(avatarImageView.snp_top)
            make.centerX.equalTo(avatarImageView.snp_right)
        }
              
        $0.backgroundColor = .init(hex: 0xE93D41)
        $0.layer.cornerRadius = 9
        $0.layer.borderWidth = 2
        $0.layer.borderColor = UIColor.white.cgColor
    }
    
    private lazy var unreadLabel = UILabel().then {
        unreadView.addSubview($0)
        $0.snp.makeConstraints { make in
            make.left.equalTo(4)
            make.right.equalTo(-4)
            make.top.bottom.equalToSuperview()
        }
             
        $0.textAlignment = .center
        $0.font = .systemFont(ofSize: 12)
        $0.textColor = .white
    }
    
    //标题
    private lazy var titleLabel = UILabel().then {
        bgView.addSubview($0)
        $0.snp.makeConstraints { make in
            make.left.equalTo(avatarImageView.snp_right).offset(14)
            make.top.equalTo(14)
            make.right.equalTo(timeLabel.snp_left).offset(-20)
        }
        
        $0.textColor = .init(hex: 0x1A1A1A)
        $0.font = .systemFont(ofSize: 16)
    }
    
    //时间
    private lazy var timeLabel = UILabel().then {
        bgView.addSubview($0)
        $0.snp.makeConstraints { make in
            make.right.equalTo(-16)
            make.top.equalTo(14)
        }
        
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        $0.setContentHuggingPriority(.required, for: .horizontal)
        
        $0.textColor = .init(hex: 0x909090)
        $0.font = .systemFont(ofSize: 12)

    }
    
    //最后一条消息
    private lazy var lastMessageLabel = UILabel().then {
        bgView.addSubview($0)
        $0.snp.makeConstraints { make in
            make.bottom.equalTo(-15)
            make.left.right.equalTo(titleLabel)
        }
        
        $0.textColor = .init(hex: 0x909090)
        $0.font = .systemFont(ofSize: 14)
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        lineView.snp.remakeConstraints { make in
            make.left.equalTo(titleLabel)
            make.right.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
     
    func setModel(_ model: RKIMGroup) {
        titleLabel.text = model.groupName.replacingOccurrences(of: "的技术支持", with: "")
        let message = model.lastMessage
        
        if let groupAvatars = model.groupAvatars {
            avatarImageView.kf.setImage(with: URL(string: groupAvatars), placeholder: nil)
        } else {
            avatarImageView.image = nil
        }

        unreadLabel.text = model.unReadCount > 99 ? "99+" : "\(model.unReadCount)"
        unreadView.isHidden = model.unReadCount == 0
        
        //服务端消息不全 由于复用cell会造成信息显示不正确
        timeLabel.text  = ""
        lastMessageLabel.text = ""
        
        guard let sendTimeLong = message?.sendTimeLong else { return }
        timeLabel.text = RKChatToolkit.formatCallDate(date: Date(timeIntervalSince1970: sendTimeLong/1000) as Date)
        guard let msgModel = message?.messageDetailModel else { return }
        var messageDetail = ""
        switch message?.messageType {
        case .Text:
            messageDetail = msgModel.content ?? ""
        case .Image:
            messageDetail = "【图片】"
        case .Video:
            messageDetail = "【视频】"
        case .Voice:
            messageDetail = "【语音】"
        case .File:
            messageDetail = "【文件】"
        case .system:
            messageDetail = msgModel.content  ?? ""
        case .Unknown:
            messageDetail = "【未知消息】"
        case .none: break
        default: break
        }
        
        var name = ""
        let member = model.userList.filter {$0.userId == message?.sender}.first
        if member != nil {
            name = member!.realName
        }

        lastMessageLabel.text = name + " : " + messageDetail

    }

}
