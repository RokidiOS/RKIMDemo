//
//  RKChatVideoCell.swift
//  RKIM
//
//  Created by chzy on 2022/2/8.
//

import SnapKit
import UIKit
import RKIMCore
import Kingfisher
import MediaPlayer
import AVKit
import RKLogger
import JXPhotoBrowser

class RKChatVideoCell: RKChatDetailCell {
    
    private var imageWidth: Double = 240.0
    private var imageHeight: Double = 240.0
    static var cellIdeString = "RKChatVideoCell"
    
    private var photoImageViewAvatarTopConstraint: Constraint?
    private var photoImageViewNickTopConstraint: Constraint?
    
    private var photoImageViewLeftConstraint: Constraint?
    private var photoImageViewRightConstraint: Constraint?

    private var photoImageViewWidthConstraint: Constraint?
    private var photoImageViewHeightConstraint: Constraint?

    lazy var photoImageView = UIImageView().then { photoImageView in
        bgView.addSubview(photoImageView)
        photoImageView.snp.makeConstraints { make in
            photoImageViewAvatarTopConstraint = make.top.equalTo(avatar).priorityMedium().constraint
            photoImageViewNickTopConstraint = make.top.equalTo(nickNameLabel.snp_bottom).offset(5).constraint
            
            photoImageViewLeftConstraint = make.left.equalTo(nickNameLabel).priorityMedium().constraint
            photoImageViewRightConstraint = make.right.equalTo(avatar.snp_left).offset(-10).constraint
            
            photoImageViewWidthConstraint = make.width.equalTo(imageWidth).constraint
            photoImageViewHeightConstraint = make.height.equalTo(imageHeight).constraint
            
            make.bottom.equalTo(-15)
            
            photoImageView.isUserInteractionEnabled = true
            photoImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(previewPhoto)))
        }
        
        resendButton.snp.makeConstraints { make in
            make.centerY.equalTo(photoImageView)
            make.width.height.equalTo(33)
            make.right.equalTo(photoImageView.snp_left)
        }
        
        uploadProgressView.snp.makeConstraints { make in
            make.top.equalTo(photoImageView.snp_bottom).offset(5)
            make.height.equalTo(3)
            make.left.right.equalTo(photoImageView)
        }
        
        let playIcon = UIImageView()
        playIcon.image = UIImage(named: "play", aclass: self.classForCoder)
        photoImageView.addSubview(playIcon)
        playIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 40, height: 40))
        }
    }
    override func setModel(_ message: RKIMMessage, _ showTime: Bool, _ isSelf: Bool) {

        var width = Double(message.messageDetailModel?.videoWidth ?? "1")!
        var height = Double(message.messageDetailModel?.videoHeight ?? "1")!

        if width > imageWidth {
            height = imageWidth / width * height
            width = imageWidth
        } else if width <= 0 {
            width = imageWidth
        }
        
        if height > imageHeight {
            width = imageHeight / height * width
            height = imageHeight
        } else if height <= 0 {
            height = imageHeight
        }
                
        let path = URL(fileURLWithPath: message.filePath())
        if path.isFileURL, FileManager.default.fileExists(atPath: message.filePath()){
            DispatchQueue.global().async {
                let asset = AVURLAsset(url: path)
                let assetGen = AVAssetImageGenerator(asset: asset)
                assetGen.appliesPreferredTrackTransform = true
                let time = CMTimeMakeWithSeconds(0.0, preferredTimescale: 1)
                var actualTime : CMTime = CMTimeMakeWithSeconds(0, preferredTimescale: 0)
            
                do {
                    let imgRef = try assetGen.copyCGImage(at: time, actualTime: &actualTime)
                    let img = UIImage(cgImage: imgRef)
                    DispatchQueue.main.async {
                        self.photoImageView.image =  img
                    }
                } catch {
                    RKLog("获取首帧失败")
                }
            }
          
        } else {
            guard let imgUrl = message.messageDetailModel?.thumbUrl else { return }
            photoImageView.kf.setImage(with: URL(string: imgUrl))
        }

        photoImageViewWidthConstraint?.updateOffset(amount: width)
        photoImageViewHeightConstraint?.update(offset: height)

        if isSelf {
            photoImageViewAvatarTopConstraint?.install()
            photoImageViewNickTopConstraint?.uninstall()

            photoImageViewLeftConstraint?.uninstall()
            photoImageViewRightConstraint?.install()
            photoImageView.snp.updateConstraints { make in
                make.bottom.equalTo(-27)
            }
        } else {
            photoImageViewAvatarTopConstraint?.uninstall()
            photoImageViewNickTopConstraint?.install()
            
            photoImageViewRightConstraint?.uninstall()
            photoImageViewLeftConstraint?.install()
            photoImageView.snp.updateConstraints { make in
                make.bottom.equalTo(-15)
            }
        }
    }
    

    @objc func previewPhoto() {
        self.delegate?.messageCellClick(self)
    }
}


import AVFoundation
import JXPhotoBrowser

class JXVideoCell: UIView, JXPhotoBrowserCell {
    
    weak var photoBrowser: JXPhotoBrowser?
    
    lazy var placeHolderImageView = UIImageView()
    lazy var player = AVPlayer()
    lazy var playerLayer = AVPlayerLayer(player: player)
    
    static func generate(with browser: JXPhotoBrowser) -> Self {
        let instance = Self.init(frame: .zero)
        instance.photoBrowser = browser
        return instance
    }
    
    required override init(frame: CGRect) {
        super.init(frame: .zero)
        backgroundColor = .black
        placeHolderImageView.contentMode = .scaleAspectFit
        let tap = UITapGestureRecognizer(target: self, action: #selector(click))
        addGestureRecognizer(tap)
        addSubview(placeHolderImageView)
        placeHolderImageView.layer.addSublayer(playerLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
        placeHolderImageView.frame = bounds
    }
    
    @objc private func click() {
        photoBrowser?.dismiss()
    }
}
