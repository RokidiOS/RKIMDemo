//
//  RKChatVoiceCell.swift
//  RKIM
//
//  Created by chzy on 2022/2/8.
//

import SnapKit
import RKUtils
import RKIMCore

class RKChatVoiceCell: RKChatDetailCell {
    
    var url: URL?
    static var cellIdeString = "RKChatVoiceCell"
    private var bubbleTopAvatarConstraint: Constraint?
    private var bubbleTopNickNameConstraint: Constraint?

    private var bubbleLeftConstraint: Constraint?
    private var bubbleRightConstraint: Constraint?

    
    //气泡
    private lazy var voiceBGView = UIView().then { bubbleView in
        self.bgView.addSubview(bubbleView)
        bubbleView.snp.makeConstraints { make in
            make.width.equalTo(240 * UI.ScreenScale)
            make.height.greaterThanOrEqualTo(40)
            make.bottom.equalTo(-15)
            
            bubbleTopAvatarConstraint = make.top.equalTo(avatar).constraint
            bubbleTopNickNameConstraint = make.top.equalTo(nickNameLabel.snp_bottom).offset(5).constraint

            bubbleLeftConstraint = make.left.equalTo(nickNameLabel).constraint
            bubbleRightConstraint = make.right.equalTo(avatar.snp_left).offset(-10).constraint
        }
        
        bubbleView.layer.cornerRadius = 4
        bubbleView.backgroundColor = .white
        bubbleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(voiceClick)))

        resendButton.snp.makeConstraints { make in
            make.centerY.equalTo(bubbleView)
            make.width.height.equalTo(33)
            make.right.equalTo(bubbleView.snp_left)
        }
        
        indicatorView.snp.makeConstraints { make in
            make.centerY.equalTo(bubbleView)
            make.right.equalTo(bubbleView.snp_left).offset(-5)
        }
        bubbleView.addSubViews([voiceAniImgView, timeDurationLabel])
        bubbleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(voicePlay)))
    }
    
    @objc func voicePlay() {
        self.delegate?.messageCellClick(self)
    }
    
    lazy var voiceAniImgView: UIImageView = {
        let imageView = UIImageView()
        imageView.animationDuration = 1
        imageView.animationRepeatCount = Int.max
        return imageView
    }()
    
    lazy var timeDurationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        return label
    }()
    
    
    //跳转到浏览器
    @objc private func voiceClick() {
      
    }

    override func setModel(_ message: RKIMMessage, _ showTime: Bool,_ isSelf: Bool) {
        let isSelf = message.direction == .send
        voiceBGView.backgroundColor = .init(hex: isSelf ? 0xCDE5FD : 0xffffff)
        
        voiceAniImgView.snp.remakeConstraints { make in
            if isSelf {
                make.right.equalTo(voiceBGView).offset(-20)
            } else {
                make.left.equalTo(voiceBGView).offset(20)
            }
            make.size.equalTo(CGSize(width: 20, height: 20))
            make.centerY.equalTo(voiceBGView)
        }
        
        timeDurationLabel.snp.remakeConstraints { make in
            if isSelf {
                make.right.equalTo(voiceAniImgView.snp_left).offset(-5)
            } else {
                make.left.equalTo(voiceAniImgView.snp_right).offset(5)
            }
            make.centerY.height.equalTo(voiceBGView)
        }
        timeDurationLabel.text = message.messageDetailModel?.duration
        guard let durationDb = Double(message.messageDetailModel?.duration ?? "1.0") else { return }
        voiceBGView.snp.updateConstraints { make in
            if durationDb > 10 {
                make.width.equalTo(100 + 50 + durationDb * 0.5)
            } else {
                make.width.equalTo(100 + durationDb * 5)
            }
        }
        
        if isSelf {
            bubbleTopNickNameConstraint?.uninstall()
            bubbleTopAvatarConstraint?.install()
            
            bubbleLeftConstraint?.uninstall()
            bubbleRightConstraint?.install()
            voiceBGView.snp.updateConstraints { make in
                make.bottom.equalTo(-27)
            }
            voiceAniImgView.image = UIImage(named: "msg_send_audio", aclass: self.classForCoder)
            voiceAniImgView.animationImages = [UIImage(named: "msg_send_audio02", aclass: self.classForCoder)!,
                                               UIImage(named: "msg_send_audio01", aclass: self.classForCoder)!,
                                               UIImage(named: "msg_send_audio", aclass: self.classForCoder)!]
        } else {
            bubbleTopAvatarConstraint?.uninstall()
            bubbleTopNickNameConstraint?.install()

            bubbleRightConstraint?.uninstall()
            bubbleLeftConstraint?.install()
            voiceBGView.snp.updateConstraints { make in
                make.bottom.equalTo(-15)
            }
            voiceAniImgView.image = UIImage(named: "msg_recv_audio", aclass: self.classForCoder)
            voiceAniImgView.animationImages = [UIImage(named: "msg_recv_audio02", aclass: self.classForCoder)!,
                                               UIImage(named: "msg_recv_audio01", aclass: self.classForCoder)!,
                                               UIImage(named: "msg_recv_audio", aclass: self.classForCoder)!]
        }
    }

}



