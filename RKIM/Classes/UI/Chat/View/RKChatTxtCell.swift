//
//  RKChatTxtCell.swift
//  RKIM
//
//  Created by chzy on 2021/11/3.
//

import Foundation
import SnapKit
import RKIUtils
import RKIMCore
import UIKit
import RKIBaseView


class RKChatTxtCell: RKChatDetailCell {
    
    var url: URL?
    static var cellIdeString = "RKChatTxtCell"
    private var bubbleTopAvatarConstraint: Constraint?
    private var bubbleTopNickNameConstraint: Constraint?

    private var bubbleLeftConstraint: Constraint?
    private var bubbleRightConstraint: Constraint?

    
    //气泡
    private lazy var bubbleView = RKCanBecomeFirstResponderView().then { bubbleView in
        self.bgView.addSubview(bubbleView)
        bubbleView.snp.makeConstraints { make in
            make.width.lessThanOrEqualTo(240 * UI.ScreenScale)
            make.height.greaterThanOrEqualTo(40)
            make.bottom.equalTo(-15)
            
            bubbleTopAvatarConstraint = make.top.equalTo(avatar).priorityMedium().constraint
            bubbleTopNickNameConstraint = make.top.equalTo(nickNameLabel.snp_bottom).offset(5).constraint

            bubbleLeftConstraint = make.left.equalTo(nickNameLabel).priorityMedium().constraint
            bubbleRightConstraint = make.right.equalTo(avatar.snp_left).offset(-10).constraint
        }
        
        bubbleView.layer.cornerRadius = 4
        bubbleView.backgroundColor = .white
        bubbleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(jumoToWKVC)))

        resendButton.snp.makeConstraints { make in
            make.centerY.equalTo(bubbleView)
            make.width.height.equalTo(33)
            make.right.equalTo(bubbleView.snp_left)
        }
        
        indicatorView.snp.makeConstraints { make in
            make.centerY.equalTo(bubbleView)
            make.right.equalTo(bubbleView.snp_left).offset(-5)
        }
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(showMenu))
        bubbleView.addGestureRecognizer(longPress)
    }
    
    @objc private func showMenu() {
        bubbleView.becomeFirstResponder()
        let menuControll = UIMenuController.shared

        if !menuControll.isMenuVisible {
            let item = UIMenuItem(title: "copy", action: #selector(copyAction))
            menuControll.menuItems = [item]
            menuControll.setTargetRect(bubbleView.frame, in: self)
            menuControll.setMenuVisible(true, animated: true)
        }
        
        bubbleView.copyBlock = {
            let pb = UIPasteboard.general
            guard let txt = self.messageLabel.text else { return  }
            pb.string = txt
            RKToast.show(withText: "复制成功", duration: 1)
        }
    }
    
    @objc private func copyAction() {
     
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
    
    //跳转到浏览器
    @objc private func jumoToWKVC() {
        guard let url = self.url else {
            return
        }
//        let url = URL(string: "https://www.baidu.com")
        //根据iOS系统版本，分别处理
        if #available(iOS 10, *) {
            UIApplication.shared.open(url, options: [:],
                                      completionHandler: {(success) in
                                        print(success)
            })
        } else {
            UIApplication.shared.openURL(url)
        }
//        let webvc = RKWKWebViewController()
//
//        webvc.url = url
//        self.superVC()?.navigationController?.pushViewController(webvc, animated: true)
    }

    override func setModel(_ message: RKIMMessage, _ showTime: Bool,_ isSelf: Bool) {
        let isSelf = message.direction == .send
        bubbleView.backgroundColor = .init(hex: isSelf ? 0xCDE5FD : 0xffffff)
        
        var color: UIColor?
        let txtStr = message.messageDetailModel?.content
        var str = message.messageType != .Text ? "未知消息" : txtStr
        str = message.messageType == .work ? (message.messageDetail ?? "") : str
        let attStr = NSMutableAttributedString(string: str ?? "")
               
        let url = RKChatToolkit.formateUrl(urlString: str ?? "")
        if url != nil {
            self.url = url
            
            attStr.addAttribute(NSAttributedString.Key.underlineStyle, value: NSNumber.init(value: NSUnderlineStyle.single.rawValue), range: NSRange(location: 0, length: attStr.length))
            color = .init(hex: 0x1964FA)
        } else {
            self.url = nil
            color = .init(hex: 0x1A1A1A)
        }
        
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

}


class RKCanBecomeFirstResponderView: UIView {
    
    var copyBlock:(()->Void)?
//    override
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if [#selector(copyAction)].contains(action) {
            return true
        }
        return false
    }
    @objc func copyAction() {
        copyBlock?()
    }
}
