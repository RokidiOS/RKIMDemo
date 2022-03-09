//
//  RecordTipView.swift
//  RKIM
//
//  Created by chzy on 2022/3/7.
//  录音提示view

import UIKit
import SnapKit

class RecordTipView: UIView {
 
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initContent()
        isHidden = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initContent() {
        centerView.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        cancelImageView.image = UIImage(named: "RecordCancel", aclass: self.classForCoder)
        recordBgView.image =  UIImage(named: "RecordingBkg", aclass: self.classForCoder)
        tooShotPromptImageView.image = UIImage(named: "MessageTooShort", aclass: self.classForCoder)
        
        noteLabel.font = .systemFont(ofSize: 14)
        noteLabel.textAlignment = .center
        
        addSubview(centerView)
        centerView.addSubViews([noteLabel,
                                cancelImageView,
                                recordingView,
                                tooShotPromptImageView])
        recordingView.addSubViews([recordBgView,
                                   signalValueImageView])
        
        centerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-30)
            make.size.equalTo(CGSize(width: 150, height: 150))
        }
        
        noteLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-6)
            make.height.equalTo(20)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().offset(-12)
        }
        
        cancelImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 100, height: 100))
            make.centerX.equalToSuperview()
            make.top.equalTo(14)
        }
        
        tooShotPromptImageView.snp.makeConstraints { make in
            make.edges.equalTo(cancelImageView)
        }
        
        recordingView.snp.makeConstraints { make in
            make.edges.equalTo(cancelImageView)
        }
        
        recordBgView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(62)
        }
        
        signalValueImageView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.width.equalTo(38)
            make.left.equalTo(recordBgView.snp_right).offset(2)
        }
        
        
    }

    private let centerView = UIView()
    private let noteLabel = UILabel()
    private let cancelImageView = UIImageView()  //取消提示
    private let signalValueImageView = UIImageView()   //音量的图片
    private let recordingView = UIView()  //录音整体的 view，控制是否隐藏
    private let recordBgView = UIImageView()
    private let tooShotPromptImageView = UIImageView()  //录音时间太短的提示
}

extension RecordTipView {
    //正在录音
    func recording() {
        self.isHidden = false
        self.cancelImageView.isHidden = true
        self.tooShotPromptImageView.isHidden = true
        self.recordingView.isHidden = false
        self.noteLabel.backgroundColor = UIColor.clear
        self.noteLabel.text = "手指上滑，取消发送"
    }
    
    //录音过程中音量的变化
    func signalValueChanged(_ value: CGFloat) {

    }

    //滑动取消
    func slideToCancelRecord() {
        self.isHidden = false
        self.cancelImageView.isHidden = false
        self.tooShotPromptImageView.isHidden = true
        self.recordingView.isHidden = true
        self.noteLabel.backgroundColor = UIColor.init(hex: 0x9C3638)
        self.noteLabel.text = "松开手指，取消发送"
    }
    
    //录音时间太短的提示
    func messageTooShort() {
        self.isHidden = false
        self.cancelImageView.isHidden = true
        self.tooShotPromptImageView.isHidden = false
        self.recordingView.isHidden = true
        self.noteLabel.backgroundColor = UIColor.clear
        self.noteLabel.text = "说话时间太短"
        //0.5秒后消失
        let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            self.endRecord()
        }
    }
    
    //录音结束
    func endRecord() {
        self.isHidden = true
    }
    
    //更新麦克风的音量大小
    func updateMetersValue(_ value: Float) {
        var index = Int(round(value))
        index = index > 7 ? 7 : index
        index = index < 0 ? 0 : index
        let array = [
            "RecordingSignal001",
            "RecordingSignal002",
            "RecordingSignal003",
            "RecordingSignal004",
            "RecordingSignal005",
            "RecordingSignal006",
            "RecordingSignal007",
            "RecordingSignal008",
        ]
        let images = array.map { imgName in
            return UIImage(named: imgName, aclass: self.classForCoder)
        }
        if let images = images as? [UIImage] {
            self.signalValueImageView.image = images[index]
        }
    }
}
