//
//  RKChatImageCell.swift
//  RKIM
//
//  Created by chzy on 2021/11/4.
//

import Foundation
import SnapKit
import UIKit
import RKIMCore
import Kingfisher

class RKChatImageCell: RKChatDetailCell {
    
    private var imageWidth: Double = 240.0
    private var imageHeight: Double = 240.0
    static var cellIdeString = "RKChatImageCell"
    
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
            
            photoImageViewLeftConstraint = make.left.equalTo(nickNameLabel).constraint
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
    }
    override func setModel(_ message: RKIMMessage, _ showTime: Bool, _ isSelf: Bool) {
//        if !message.existFile {
//            //下载原图
//            JCCloudManager.shared().dispatchIm {
//                JCMessageWrapper.downloadFile(message._id, fileUrl: message.file_url, savePath: RKFileUtil.randomImagePath())
//            }
//        }
        
//        let extra = message.extra
//        let extraDic = JCJson.json(toObj: extra) as? Dictionary<String, Any>

        var width = Double(message.messageDetailModel?.imgWidth ?? "1")!
        var height = Double(message.messageDetailModel?.imgHeight ?? "1")!

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
                
        let path = NSURL.init(fileURLWithPath: message.filePath())
        ///本地图片
        if path.isFileURL, FileManager.default.fileExists(atPath: message.filePath()){
            photoImageView.image = UIImage(contentsOfFile: message.filePath())
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
