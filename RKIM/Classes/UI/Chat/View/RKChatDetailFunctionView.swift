//
//  RKChatDetailFunctionView.swift
//  RokidSDK
//
//  Created by 金志文 on 2021/9/13.
//

import UIKit
import SnapKit
import RKIBaseView
import RKIUtils
import sqlcipher

enum VoiceStateType: String {
    /// 显示向上滑动取消
    case moveUpCancel = "上滑取消,松开发送"
    /// 显示松开取消
    case MoveOutCancel = "松开取消"
    /// 停止显示
    case hiden = "隐藏"
}

protocol RKChatDetailFunctionDelegate: NSObjectProtocol {
    /// 显示键盘
    func keyboardIsShow(_ isShow: Bool)
    /// 滑倒底部
    func scrollToBottom(_ animation:Bool)
    
    /// 选择照片
    func goImage()
    ///  相机
    func goCamera()
    /// 协作
    func goMeeting()
    ///  发送文字信息
    func sendTxtMessage(_ messageString: String)
    /// 发送音频
    func sendVoiceMessage()
    
    /// 显示音频录制控制
    func showVideoInfo(_ state:VoiceStateType)

    /// 声音音量
    func showVoideDegree(_ meters: Float)
    
    /// 音频时间太短
    func messageTooShort()
}

private class RKChatDetailFunctionCell: UICollectionViewCell {
    
    var clickFunctionBlock: (() -> Void)?
    
    private lazy var functionButton = UIButton(type: .custom).then {
        self.contentView.addSubview($0)
        $0.snp.makeConstraints { make in
            make.top.equalTo(18)
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 63, height: 63))
        }
        
        $0.backgroundColor = .init(hex: 0xF9F9F9)
        $0.addTarget(self, action: #selector(clickFunction), for: .touchUpInside)
    }
    
    private lazy var titleLabel = UILabel().then {
        self.contentView.addSubview($0)
        $0.snp.makeConstraints { make in
            make.top.equalTo(functionButton.snp_bottom).offset(6)
            make.centerX.equalToSuperview()
        }
        
        $0.font = .systemFont(ofSize: 12)
        $0.textColor = .init(hex: 0x727272)
    }
    
    func setModel(_ title: String, icon: String) {
        functionButton.setImage(UIImage(named: icon, aclass: self.classForCoder), for: .normal)
        titleLabel.text = title
    }
    
    @objc private func clickFunction() {
        clickFunctionBlock?()
    }
}

class RKChatDetailFunctionView: UIView {

    weak var delegate: RKChatDetailFunctionDelegate?
    
    var serverId: String = ""
    var minTimeDuration = 2
    
    enum ActionType: String {
        case selectPhoto
        case takePhoto
        case meeting
    }
    
    private var topViewBottomConstaint : Constraint?
    private var bottomViewBottomConstaint : Constraint?

    private let functionList = [
        [
            "icon": "function_photo",
            "title": "图片",
            "action": ActionType.selectPhoto
        ],
        [
            "icon": "function_camera",
            "title": "拍摄",
            "action": ActionType.takePhoto
        ],
        [
            "icon": "function_meeting",
            "title": "协作",
            "action": ActionType.meeting
        ]
    ]
    
    lazy var topView = UIView().then {
        self.addSubview($0)
        $0.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(54)
            self.topViewBottomConstaint = make.bottom.equalTo(self.snp_bottomMargin).constraint
        }
        
        $0.backgroundColor = .white
    }
    
    lazy var textView = UITextView().then {
        self.topView.addSubview($0)
        $0.snp.makeConstraints { make in
            make.left.equalTo(54)
            make.right.equalTo(-54)
            make.height.equalTo(36)
            make.centerY.equalToSuperview()
        }
        
        $0.delegate = self
        $0.enablesReturnKeyAutomatically = true
        $0.returnKeyType = .send
        $0.font = .systemFont(ofSize: 16)
        $0.textColor = .init(hex: 0x1A1A1A)
        $0.backgroundColor = .init(hex: 0xF5F5F5)
    }
    
    private lazy var functionButton = UIButton(type: .custom).then {
        self.topView.addSubview($0)
        $0.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalTo(-12)
            make.size.equalTo(CGSize(width: 30, height: 30))
        }
        
        $0.setBackgroundImage(UIImage(named: "show_function", aclass: self.classForCoder), for: .normal)
        $0.addTarget(self, action: #selector(showFunction), for: .touchUpInside)
    }
    
    lazy var voiceButton: UIButton = {
        let btn = UIButton()
        topView.addSubview(btn)
        btn.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(12)
            make.size.equalTo(CGSize(width: 30, height: 30))
        }
        
        btn.setBackgroundImage(UIImage(named: "show_voice", aclass: self.classForCoder), for: .normal)
        btn.addTarget(self, action: #selector(showVoiceFunction), for: .touchUpInside)
        return btn
    }()
    
    lazy var recordButton: UIButton = {
        let btn = UIButton()
        topView.addSubview(btn)
        btn.snp.makeConstraints { make in
            make.edges.equalTo(textView)
        }
        btn.setTitle("按住说话", for: .normal)
        btn.backgroundColor = UIColor.init(hex: 0xdbdbdb)
        btn.titleLabel?.textAlignment = .center
        btn.setTitleColor(UIColor.black.withAlphaComponent(0.4), for: .normal)
        
        btn.addTarget(self, action: #selector(recordStart), for: .touchDown)
        btn.addTarget(self, action: #selector(recordFinish), for: .touchUpInside)
        btn.addTarget(self, action: #selector(recordCancel), for: .touchUpOutside)
//        btn.addTarget(self, action: #selector(dragIn), for: .touchDragInside)
//        btn.addTarget(self, action: #selector(dragOut), for: .touchDragOutside)
        btn.addTarget(self, action: #selector(dragAction(sendButton:event:)), for: .touchDragInside)
        btn.addTarget(self, action: #selector(dragAction(sendButton:event:)), for: .touchDragOutside)
        return btn
    }()
    
    //底部view 包含功能视图和取消按钮
    private lazy var bottomView = UIView().then {
        self.addSubview($0)
        $0.snp.makeConstraints { make in
            make.top.equalTo(topView.snp_bottom)
            make.left.right.equalToSuperview()
        }
        
        $0.backgroundColor = .white
        
        let lineView = UIView()
        
        $0.addSubview(lineView)
        lineView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
        lineView.backgroundColor = .init(hex: 0x000000, alpha: 0.1)
    }
    
    private lazy var layout  = UICollectionViewFlowLayout().then {
        $0.itemSize = CGSize(width: UI.ScreenWidth / 4.0, height: 130)
        $0.minimumLineSpacing = 0
        $0.minimumInteritemSpacing = 0
        $0.scrollDirection = .horizontal
    }
    
    //功能视图
    private lazy var functionView = UICollectionView(frame: .zero, collectionViewLayout: self.layout).then {
        self.bottomView.addSubview($0)
        $0.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(0.5)
            make.height.equalTo(130)
        }
        
        $0.backgroundColor = .white
        $0.delegate = self
        $0.dataSource = self
        
        $0.register(RKChatDetailFunctionCell.self, forCellWithReuseIdentifier: "cell")
    }
    
    //取消按钮
    private lazy var cancelButton = UIButton(type: .system).then {
        self.bottomView.addSubview($0)
        $0.snp.makeConstraints { make in
            make.top.equalTo(self.functionView.snp_bottom).offset(15)
            make.bottom.equalTo(-15).priority(.medium)
            make.centerX.equalToSuperview()
        }
        
        $0.titleLabel?.font = .systemFont(ofSize: 16)
        $0.setTitle("取消", for: .normal)
        $0.setTitleColor(.black, for: .normal)
        $0.addTarget(self, action: #selector(hideFunction), for: .touchUpInside)
    }
    
    
    init() {
        super.init(frame: .zero)
        
        backgroundColor = .white
        
        textView.isHidden = false
        functionButton.isHidden = false
        voiceButton.isHidden = false
        recordButton.isHidden = true
        
        bottomView.isHidden = true
        functionView.isHidden = false
        cancelButton.isHidden = false
        
    }
    
    func addKeyboardNotif() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func removeKeyboardNotif() {
        NotificationCenter.default.removeObserver(self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    var isFunctionShow = false
    
    @objc func hideFunction () {
        isFunctionShow = false
        textView.resignFirstResponder()
        if self.bottomView.isHidden == true {
            return
        }

        UIView.animate(withDuration: 0.2) {
            self.topView.snp.remakeConstraints { make in
                make.top.left.right.equalToSuperview()
                make.height.equalTo(54)
                make.bottom.equalTo(self.snp_bottomMargin)
            }

            self.bottomView.snp.remakeConstraints { make in
                make.top.equalTo(self.topView.snp_bottom)
                make.left.right.equalToSuperview()
            }
            
            self.superview?.layoutIfNeeded()
        } completion: { complete in
            if complete {
                self.delegate?.keyboardIsShow(false)
                self.bottomView.isHidden = true
            }
        }
        delegate?.scrollToBottom(false)
    }
    
    @objc private func showFunction() {
        isFunctionShow = true
        recordButton.isHidden = true
        if textView.isFirstResponder {
            textView.resignFirstResponder()
        } else {
            textView.becomeFirstResponder()
        }
        UIView.animate(withDuration: 0.2) {
            self.bottomView.snp.remakeConstraints { make in
                make.top.equalTo(self.topView.snp_bottom)
                make.bottom.equalTo(self.snp_bottomMargin)
                make.left.right.equalToSuperview()
            }
            
            self.topView.snp.remakeConstraints { make in
                make.top.left.right.equalToSuperview()
                make.height.equalTo(54)
            }
            
            self.superview?.layoutIfNeeded()
            
            self.bottomView.isHidden = false
        }
        self.delegate?.keyboardIsShow(true)
        delegate?.scrollToBottom(false)
    }

    @objc private func showVoiceFunction() {
        recordButton.isHidden = !recordButton.isHidden
        if recordButton.isHidden {
            textView.becomeFirstResponder()
        } else {
            textView.resignFirstResponder()
        }
    }
    
    
}

extension RKChatDetailFunctionView: UICollectionViewDelegate {
    
}

extension RKChatDetailFunctionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return functionList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! RKChatDetailFunctionCell
        let functionData = functionList[indexPath.row]
        
        cell.setModel(functionData["title"]! as! String, icon: functionData["icon"]! as! String)
        cell.clickFunctionBlock = { [weak self] in
            guard let function = functionData["action"] as? ActionType else { return }
            switch function {
            case .selectPhoto:
                self?.delegate?.goImage()
                break
            case .takePhoto:
                self?.delegate?.goCamera()
                break
            case .meeting:
                self?.delegate?.goMeeting()
                break
            }
        }
        
        return cell
    }
    
}

//监听回调
extension RKChatDetailFunctionView {
    
    @objc func keyboardWillShow(_ noti: Notification) {
        guard let keyboardFrame = (noti.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let duration = (noti.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue else { return }
        isFunctionShow = false
        bottomView.isHidden = true
        
        UIView.animate(withDuration: duration) {
            self.topView.snp.remakeConstraints { make in
                make.top.left.right.equalToSuperview()
                make.height.equalTo(54)
                make.bottom.equalTo(-keyboardFrame.height)
            }

            self.bottomView.snp.remakeConstraints { make in
                make.top.equalTo(self.topView.snp_bottom)
                make.left.right.equalToSuperview()
            }
            
            self.superview?.layoutIfNeeded()
        }
        self.delegate?.keyboardIsShow(true)
        delegate?.scrollToBottom(false)

    }
    
    @objc func keyboardWillHide(_ noti: Notification) {

        if isFunctionShow { return }
        guard let duration = (noti.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
            else {
                return
        }
        
        self.topView.snp.remakeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(54)
            make.bottom.equalTo(self.snp_bottomMargin)
        }

        self.bottomView.snp.remakeConstraints { make in
            make.top.equalTo(self.topView.snp_bottom)
            make.left.right.equalToSuperview()
        }
        
        UIView.animate(withDuration: duration) {
            self.superview?.layoutIfNeeded()
        }
        self.delegate?.keyboardIsShow(false)
//        delegate?.scrollToBottom(false)
    }
    
}

extension RKChatDetailFunctionView: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            //全部是空格拒绝发送，否则原样发送  参考微信

           guard let text = textView.text?.trimmingCharacters(in: .whitespaces), text.count > 0 else { return false }
            delegate?.sendTxtMessage(text)
            textView.text = nil
            
            return false
        }
        
        return true
    }
}

/// record
extension RKChatDetailFunctionView {
    @objc private func recordStart() {
        print("开始录制")
        RKRecordTool.shareManager.recordUpdate = { meters in
            self.delegate?.showVoideDegree(meters)
        }
        
        RKRecordTool.shareManager.startRecord()
        delegate?.showVideoInfo(.moveUpCancel)
        
        RKRecordTool.shareManager.autoFinishBlock = {
            let timeduration = RKRecordTool.shareManager.seconds
            if self.minTimeDuration > timeduration {
                self.delegate?.messageTooShort()
                return
            }
            self.delegate?.sendVoiceMessage()
        }
    }
    
    @objc private func recordCancel() {
        print("录制取消")
        RKRecordTool.shareManager.stopRecord()
        delegate?.showVideoInfo(.hiden)
    }
    
    @objc private func recordFinish() {
        print("完成完成")
        RKRecordTool.shareManager.stopRecord()
        delegate?.showVideoInfo(.hiden)
        RKRecordTool.shareManager.autoFinishBlock?()
      
    }
    
    @objc private func dragAction(sendButton: UIButton, event: UIEvent) {
        if isIn(buttonBound: sendButton, event: event) {
            delegate?.showVideoInfo(.moveUpCancel)
        } else {
            delegate?.showVideoInfo(.MoveOutCancel)
        }
    }
    
    private func isIn(buttonBound btn:UIButton, event: UIEvent) -> Bool {
        if let touch = event.allTouches?.first {
            let point = touch.location(in: btn)
            let boundsExtension = 1.0
            let outerBounds = btn.bounds.insetBy(dx: -1 * boundsExtension, dy: -1 * boundsExtension)
            let touchOutSide = outerBounds.contains(point)
            if touchOutSide {
               return true
            } else {
                return false
            }
        }
        
        
        return false
    }
    
    @objc private func dragIn() {
        delegate?.showVideoInfo(.moveUpCancel)
    }
    
    @objc private func dragOut() {
        delegate?.showVideoInfo(.MoveOutCancel)
    }
}
