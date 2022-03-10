//
//  RKChatFileCell.swift
//  RKIM
//
//  Created by chzy on 2022/2/21.
//

import Foundation
import SnapKit
import RKIUtils
import RKIMCore

class RKChatFileCell: RKChatDetailCell {
    
    var url: URL?
    static var cellIdeString = "RKChatFileCell"
    private var bubbleTopAvatarConstraint: Constraint?
    private var bubbleTopNickNameConstraint: Constraint?

    private var bubbleLeftConstraint: Constraint?
    private var bubbleRightConstraint: Constraint?

    
    //气泡
    private lazy var bubbleView = UIView().then { bubbleView in
        self.bgView.addSubview(bubbleView)
        bubbleView.snp.makeConstraints { make in
            make.width.lessThanOrEqualTo(240 * UI.ScreenScale)
            make.height.greaterThanOrEqualTo(40)
            make.bottom.equalTo(-15)
            
            bubbleTopAvatarConstraint = make.top.equalTo(avatar).constraint
            bubbleTopNickNameConstraint = make.top.equalTo(nickNameLabel.snp_bottom).offset(5).constraint

            bubbleLeftConstraint = make.left.equalTo(nickNameLabel).constraint
            bubbleRightConstraint = make.right.equalTo(avatar.snp_left).offset(-10).constraint
        }
        
        bubbleView.layer.cornerRadius = 4
        bubbleView.backgroundColor = .white
     
        resendButton.snp.makeConstraints { make in
            make.centerY.equalTo(bubbleView)
            make.width.height.equalTo(33)
            make.right.equalTo(bubbleView.snp_left)
        }
        
        indicatorView.snp.makeConstraints { make in
            make.centerY.equalTo(bubbleView)
            make.right.equalTo(bubbleView.snp_left).offset(-5)
        }
        bubbleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(previewFile)))
    }
    
    //消息内容
    private lazy var messageLabel = UILabel().then {
        self.bubbleView.addSubview($0)
        $0.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
        }
        
        $0.isUserInteractionEnabled = false
        $0.textColor = .init(hex: 0x1A1A1A)
        $0.font = .systemFont(ofSize: 16)
        $0.numberOfLines = 0
    }
    
    override func setModel(_ message: RKIMMessage, _ showTime: Bool,_ isSelf: Bool) {
        let isSelf = message.direction == .send
        bubbleView.backgroundColor = .init(hex: isSelf ? 0xCDE5FD : 0xffffff)
        
        var color: UIColor?
        guard let txtStr = message.messageDetailModel?.fileName else {
            return
        }
        let fileDes =  "【文件消息】" + txtStr
        let str = message.messageType != .File ? "未知消息" : fileDes
        let attStr = NSMutableAttributedString(string: str)
               
        self.url = nil
        color = .brown
        
        attStr.addAttribute(NSAttributedString.Key.foregroundColor, value: color!, range: NSRange(location: 0, length: attStr.length))

        messageLabel.attributedText = attStr

        if isSelf {
            bubbleTopNickNameConstraint?.uninstall()
            bubbleTopAvatarConstraint?.install()
            
            bubbleLeftConstraint?.uninstall()
            bubbleRightConstraint?.install()
            bubbleView.snp.updateConstraints { make in
                make.bottom.equalTo(-27)
            }
        } else {
            bubbleTopAvatarConstraint?.uninstall()
            bubbleTopNickNameConstraint?.install()

            bubbleRightConstraint?.uninstall()
            bubbleLeftConstraint?.install()
            bubbleView.snp.updateConstraints { make in
                make.bottom.equalTo(-15)
            }
        }
    }

    @objc func previewFile() {
        self.delegate?.messageCellClick(self)
    }
}
