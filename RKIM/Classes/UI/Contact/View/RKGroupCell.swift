//
//  RKGroupCell.swift
//  RKIM
//
//  Created by chzy on 2021/11/2.
//

import Foundation
import RKIUtils

class RKAddressBookGroupListCell: UITableViewCell {
    // 头像
    var avatarImageView: UIImageView!
    // 名字
    var nameLabel: UILabel!
    // 状态
    var memeberLabel: UILabel!
    // 右侧呼叫
    var callButton: UIButton!
    // 底部横线
    var lineView: UIView!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        
        avatarImageView = UIImageView()
        avatarImageView.layer.cornerRadius = 22
        avatarImageView.layer.masksToBounds = true
        self.contentView.addSubview(avatarImageView)
        
        nameLabel = UILabel()
        nameLabel.font = RKFont.font_mainText
        nameLabel.textColor = UIColor(hex: 0x000000)
        self.contentView.addSubview(nameLabel)
        
        memeberLabel = UILabel()
        memeberLabel.font = RKFont.font_tipText
        memeberLabel.textColor = UIColor(hex: 0x909090)
        self.contentView.addSubview(memeberLabel)
        
        callButton = UIButton()
        let callImage = UIImage(named: "rk_btn_start_blue")
        callButton.setImage(callImage, for: .normal)
        self.contentView.addSubview(callButton)
        
        lineView = UIView()
        lineView.backgroundColor = UIColor(hex: 0xF3F3F3)
        self.contentView.addSubview(lineView)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        avatarImageView.snp.makeConstraints { (make) in
            make.size.equalTo(44)
            make.left.equalTo(20)
            make.centerY.equalToSuperview()
        }
        
        nameLabel.snp.makeConstraints { (make) in
            make.top.equalTo(13)
            make.left.equalTo(avatarImageView.snp_right).offset(10)
            make.width.equalTo(100)
            make.height.equalTo(20)
        }
        
        memeberLabel.snp.makeConstraints { (make) in
            make.top.equalTo(nameLabel.snp_bottom)
            make.left.equalTo(nameLabel)
            make.width.equalTo(50)
            make.height.equalTo(20)
        }
        
        callButton.snp.makeConstraints { (make) in
            make.right.equalTo(-20)
            make.centerY.equalToSuperview()
            make.size.equalTo(44)
        }
        
        lineView.snp.makeConstraints { (make) in
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
    }
}
