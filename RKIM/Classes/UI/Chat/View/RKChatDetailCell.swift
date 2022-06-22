//
//  RKChatDetailCell.swift
//  RKIM
//
//  Created by chzy on 2021/11/3.
//  聊天详情cell 基类

import Foundation
import RKIUtils
import Then
import RKIBaseView
import SnapKit
import RKIMCore
import UIKit

protocol RKChatDetailCellDelegate: NSObjectProtocol {
    /// 重新发送消息
    func resendAction(_ cell: RKChatDetailCell)
    /// 点击消息cell
    func messageCellClick(_ cell: RKChatDetailCell)
    /// 查看消息已读未读详情
    func showUnreadInfo(_ cell: RKChatDetailCell)
}

class RKChatDetailCell: RKBaseCell {
    
    var memberList: [RKIMGroup] = []
    var message: RKIMMessage?
    weak var delegate: RKChatDetailCellDelegate?
    enum RKChatMessageType {
        case text
        case image
        case video
        case audio
    }
    
    private var timeLabelTopConstraint: Constraint?
    private var timeLabelHeightConstraint: Constraint?
    private var avatarLeftConstraint: Constraint?
    private var avatarRightConstraint: Constraint?

    //消息发送时间 两次发送时间间隔超过5分钟显示
    lazy var timeLabel = UILabel().then {
        self.bgView.addSubview($0)
        $0.snp.makeConstraints { make in
            timeLabelTopConstraint = make.top.equalTo(0).priorityMedium().constraint
            make.centerX.equalToSuperview()
            timeLabelHeightConstraint = make.height.equalTo(20).constraint
        }
        
        $0.textColor = .init(hex: 0x9F9F9F)
        $0.font = .systemFont(ofSize: 14)
    }

    //头像
    lazy var avatar = UIImageView().then {
        self.bgView.addSubview($0)
        $0.snp.makeConstraints { make in
            make.top.equalTo(timeLabel.snp_bottom).offset(15)
            make.size.equalTo(CGSize(width: 40, height: 40))
            
            avatarLeftConstraint = make.left.equalTo(12).priorityMedium().constraint
            avatarRightConstraint = make.right.equalTo(-12).constraint
        }
        
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        $0.setCorner(radius: 8)
    }
    
    //昵称
    lazy var nickNameLabel = UILabel().then {
        self.bgView.addSubview($0)
        $0.snp.makeConstraints { make in
            make.top.equalTo(avatar).priorityLow()
            make.left.equalTo(avatar.snp_right).offset(10).priorityLow()
        }
        
        $0.textColor = .init(hex: 0x9F9F9F)
        $0.font = .systemFont(ofSize: 12)
    }
    
    //重新发送按钮
    lazy var resendButton = UIButton(type: .custom).then {
        self.bgView.addSubview($0)
        
        $0.setImage(UIImage(named: "upload_fail", aclass: self.classForCoder), for: .normal)
        $0.addTarget(self, action: #selector(resendAction), for: .touchUpInside)
    }
    
    //发送中的indicate
    lazy var indicatorView = UIActivityIndicatorView(style: .gray).then {
        $0.hidesWhenStopped = true
        bgView.addSubview($0)
    }
        
    //上传文件进度
    lazy var uploadProgressView = UIProgressView().then {
        $0.progressTintColor = .init(hex: 0x1964FA)
        $0.trackTintColor = .white
        
        self.bgView.addSubview($0)
    }
    
    //已读未读状态
    lazy var unreadInfoButton: UIButton = {
        let btn = UIButton()
        btn.addTarget(self, action: #selector(showDetailUnreadInfo), for: .touchUpInside)
        btn.setTitleColor(UIColor.init(hex: 0x0E90FF), for: .normal)
        btn.setTitle("查看已读详情", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        btn.setContentHuggingPriority(.required, for: .horizontal)
        btn.layer.cornerRadius = 6
        btn.clipsToBounds = true
        contentView.addSubview(btn)
        btn.snp.makeConstraints { make in
            make.bottom.equalTo(bgView).offset(-4)
            make.right.equalTo(avatar.snp_left).offset(-10)
            make.height.equalTo(17)
        }
        return btn
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        
        backgroundColor = .init(hex: 0xF8F9FB)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setModel(_ message: RKIMMessage, _ showTime: Bool) {
        self.message = message
        let isSelf = message.direction == .send
        
        timeLabel.isHidden = !showTime
        timeLabel.text = RKChatToolkit.formatMessageDate(date: Date(timeIntervalSince1970: message.sendTimeLong/1000) as Date)

        
        let nickName = message.senderName
        
        let avatarUrl = message.senderAvator
        
        avatar.kf.setImage(with: URL(string: avatarUrl), placeholder: UIImage(named: "default_avatar", aclass: self.classForCoder))
        //产品要求 自己的消息也要展示用户名
//        nickNameLabel.isHidden = isSelf
        nickNameLabel.text = nickName
        if isSelf {
            #warning("TODO")
//            nickNameLabel.text =  DemoUserCenter.userInfo.realName
//            avatar.kf.setImage(with: URL(string: DemoUserCenter.userInfo.headPortrait))

        } else if nickNameLabel.text!.isEmpty {
            DBHelper.asyUser(message.sender) { contact in
                if let contact = contact {
                    message.senderName = contact.realName
                    message.senderAvator = contact.headPortrait
                    
                    self.nickNameLabel.text = contact.realName
                    self.avatar.kf.setImage(with: URL(string: contact.headPortrait))
                }
            }
        }
        
        let messageState = message.status
        resendButton.isHidden = !(messageState == .fail && message.direction == .send)
        
        uploadProgressView.isHidden = !(message.direction == .send && messageState == .transfering && message.messageType != .Text)
        uploadProgressView.setProgress(message.progess, animated: false)
        //文本消息发送中展示 菊花
        if message.messageType == .Text && message.direction == .send && messageState == .transfering {
            indicatorView.startAnimating()
        } else {
            indicatorView.stopAnimating()
        }
    
        if showTime {
            timeLabelTopConstraint?.update(inset: 12)
            timeLabelHeightConstraint?.update(offset: 20)
        } else {
            timeLabelTopConstraint?.update(inset: 0)
            timeLabelHeightConstraint?.update(offset: 5)
        }
        
        unreadInfoButton.isHidden = true
        if isSelf {
            avatarLeftConstraint?.uninstall()
            avatarRightConstraint?.install()
           
            if let unreadCount = message.unread, !message.id.isEmpty {
                if unreadCount == 0 {
                    unreadInfoButton.setTitle("全部已读", for: .normal)
                    unreadInfoButton.setTitleColor(UIColor.init(hex: 0xA6A7A9), for: .normal)
                } else {
                    unreadInfoButton.setTitle("还剩\(unreadCount)未读", for: .normal)
                    unreadInfoButton.setTitleColor(UIColor.init(hex: 0x0E90FF), for: .normal)
                }
                unreadInfoButton.isHidden = false
            }
         
            nickNameLabel.snp.remakeConstraints({ make in
                make.bottom.equalTo(avatar.snp_top).offset(-4)
                make.right.equalTo(avatar.snp_right)
            })
        } else {
            avatarLeftConstraint?.install()
            avatarRightConstraint?.uninstall()
            nickNameLabel.snp.remakeConstraints({ make in
                make.top.equalTo(avatar).priorityLow()
                make.left.equalTo(avatar.snp_right).offset(10).priorityLow()
            })
        }
        
        setModel(message, showTime, isSelf)
    }
    
    func setModel(_ message: RKIMMessage, _ showTime: Bool, _ isSelf: Bool) {
        
    }
    
    @objc func resendAction() {
        self.delegate?.resendAction(self)
    }
    
    @objc func showDetailUnreadInfo() {
        self.delegate?.showUnreadInfo(self)
    }
}


