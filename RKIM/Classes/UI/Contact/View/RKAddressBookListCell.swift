//
//  AddressBookListCell.swift
//  RokidSDK
//
//  Created by Rokid on 2021/8/12.
//  联系人列表 cell
import RKIUtils

enum CellState: Int {
    case offline        = 0 // 离线
    case online         = 1 // 在线
    case onlineBusy     = 2 // 在线正忙
    case group          = 3 // 群组
}

enum ChooseEnum: Int {
    case unchoosed = 0
    case choosed = 1
    case unknown = 2
}

class RKAddressBookListCell: UITableViewCell {
    
    // 头像
    var avatarImageButton: UIButton!
    // 名字
    var nameLabel: UILabel!
    // 状态
    var statePointView: UIView!
    var stateLabel: UILabel!
    // 右侧选择框
    var pickImageView: UIImageView!
    // 底部横线
    var lineView: UIView!
    // 状态
    var cellState: CellState = .offline {
        didSet {
            switch cellState {
            case .offline:
                stateLabel.isHidden = false
                stateLabel.text = "离线"
                stateLabel.textColor = UIColor(hex: 0x999999)
                statePointView.backgroundColor = UIColor(hex: 0x999999)
                pickImageView.image = nil
            case .online:
                stateLabel.isHidden = false
                stateLabel.text = "在线"
                stateLabel.textColor = UIColor(hex: 0x1ECA39)
                statePointView.backgroundColor = UIColor(hex: 0x1ECA39)
                let checkboxImage = UIImage(named: "rk_checkbox_n",aclass: self.classForCoder)
                pickImageView.image = checkboxImage
            case .onlineBusy:
                stateLabel.isHidden = false
                stateLabel.text = "协作中"
                stateLabel.textColor = UIColor(hex: 0xFF8A00)
                statePointView.backgroundColor = UIColor(hex: 0xFF8A00)
                pickImageView.image = nil
            default: break
            }
        }
    }
    
    var isChoosed: ChooseEnum  = .unknown {
        didSet {
            switch isChoosed {
            case .unknown:
                pickImageView.image = nil
            case .unchoosed:
                let checkboxImage = UIImage(named: "rk_checkbox_n",aclass: self.classForCoder)
                pickImageView.image = checkboxImage
            case .choosed:
                let checkboxImage = UIImage(named: "rk_checkbox_s",aclass: self.classForCoder)
                pickImageView.image = checkboxImage
            }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        
        avatarImageButton = UIButton(type: .custom)
        avatarImageButton.layer.cornerRadius = 22
        avatarImageButton.layer.masksToBounds = true
        self.contentView.addSubview(avatarImageButton)
        
        nameLabel = UILabel.init()
        nameLabel.font = RKFont.font_mainText
        nameLabel.textColor = UIColor(hex: 0x000000)
        self.contentView.addSubview(nameLabel)
        
        statePointView = UIView()
        statePointView.layer.cornerRadius = 2.5
        statePointView.backgroundColor = UIColor(hex: 0x909090)
        self.contentView.addSubview(statePointView)
        
        stateLabel = UILabel()
        stateLabel.font = RKFont.font_tipText
        stateLabel.textColor = UIColor(hex: 0x909090)
        self.contentView.addSubview(stateLabel)
        
        pickImageView = UIImageView.init()
        let accImage = UIImage(named: "rk_cell_acc", aclass: self.classForCoder)
        pickImageView.image = accImage
        self.contentView.addSubview(pickImageView)
        
        lineView = UIView.init()
        lineView.backgroundColor = UIColor(hex: 0xF3F3F3)
        self.contentView.addSubview(lineView)
    }
    
    func getStateAttributedText(_ text: String) -> NSMutableAttributedString {
        let att = [NSAttributedString.Key.font: RKFont.font_title] as [NSAttributedString.Key : Any]
        let attString = NSMutableAttributedString(string: text)
        attString.addAttributes(att, range:NSRange.init(location: 0, length: 1))
        return attString
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        avatarImageButton.snp.makeConstraints { (make) in
            make.size.equalTo(44)
            make.left.equalTo(20)
            make.centerY.equalToSuperview()
        }
        
        nameLabel.snp.makeConstraints { (make) in
            make.top.equalTo(13)
            make.left.equalTo(avatarImageButton.snp_right).offset(10)
            make.right.equalTo(pickImageView.snp_left).offset(-10)
            make.height.equalTo(20)
        }
        
        statePointView.snp.makeConstraints { (make) in
            make.left.equalTo(nameLabel)
            make.size.equalTo(5)
            make.centerY.equalTo(stateLabel)
        }
        
        stateLabel.snp.makeConstraints { (make) in
            make.top.equalTo(nameLabel.snp_bottom)
            make.left.equalTo(statePointView.snp_right).offset(5)
            make.width.equalTo(50)
            make.height.equalTo(20)
        }
        
        pickImageView.snp.makeConstraints { (make) in
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
