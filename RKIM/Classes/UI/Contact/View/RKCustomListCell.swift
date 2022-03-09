//
//  RKCustomListCell.swift
//  RokidSDK
//
//  Created by Rokid on 2021/8/12.
//
import RKUtils

class RKCustomListCell: UITableViewCell {
    
    // 左值
    var titleLabel: UILabel!
    // 右值
    var detailLabel: UILabel!
    // 底部横线
    var lineView: UIView!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .gray
        
        titleLabel = UILabel.init()
        titleLabel.font = RKFont.font_mainText
        titleLabel.textColor = UIColor(hex: 0x101010)
        self.contentView.addSubview(titleLabel)
        
        detailLabel = UILabel.init()
        detailLabel.font = RKFont.font_mainText
        detailLabel.textColor = UIColor(hex: 0x959595)
        detailLabel.textAlignment = .right
        self.contentView.addSubview(detailLabel)
        
        lineView = UIView.init()
        lineView.backgroundColor = UIColor(hex: 0xF3F3F3)
        self.contentView.addSubview(lineView)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        titleLabel.snp.makeConstraints { (make) in
            make.top.height.equalToSuperview()
            make.left.equalTo(20)
            make.width.equalTo(140)
        }
        
        detailLabel.snp.makeConstraints { (make) in
            make.top.height.equalToSuperview()
            make.left.equalTo(titleLabel.snp_right)
            make.right.equalTo(-20)
        }
        
        lineView.snp.makeConstraints { (make) in
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
    }
}
