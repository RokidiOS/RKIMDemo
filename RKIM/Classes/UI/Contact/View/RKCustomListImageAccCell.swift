//
//  RKCustomListImageAccCell.swift
//  RokidSDK
//
//  Created by Rokid on 2021/8/18.
//

class RKCustomListImageAccCell: RKCustomListAccCell {
    
    var iconImageView: UIImageView!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .gray
        
        iconImageView = UIImageView()
        iconImageView.contentMode = .scaleAspectFit
        self.contentView.addSubview(iconImageView)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        
        iconImageView.snp.makeConstraints { (make) in
            make.left.equalTo(20)
            make.centerY.equalToSuperview()
            make.size.equalTo(44)
        }
        
        titleLabel.snp.makeConstraints { (make) in
            make.top.height.equalToSuperview()
            make.left.equalTo(iconImageView.snp_right).offset(10)
            make.width.equalTo(140)
        }
        
        detailLabel.snp.remakeConstraints { (make) in
            make.top.height.equalToSuperview()
            make.left.equalTo(titleLabel.snp_right)
            make.right.equalTo(accImageView.snp_left)
        }
        
        accImageView.snp.makeConstraints { (make) in
            make.right.equalTo(-20)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
        
        lineView.snp.makeConstraints { (make) in
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
    }
}
