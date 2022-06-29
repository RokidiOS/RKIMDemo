//
//  RKChatSystemCell.swift
//  RKIM
//
//  Created by chzy on 2021/11/17.
//

import UIKit
import SnapKit
import RKIMCore

class RKChatSystemCell: UITableViewCell {
    static let cellIdeString = "RKChatSystemCell"

    func setModel(_ message: RKIMMessage, _ showTime: Bool = true) {
        infoLb.text = message.messageDetailModel?.content
        var names = ""
        if let userIdList = message.messageDetailModel?.userIdList {
           let nameArray = userIdList.map{ (id) -> String in
               return id.userName() ?? ""
            }
            names = nameArray.joined(separator: "、")
        }
        
        if message.messageDetailModel?.systemType == .InvitGroup {
            infoLb.text = names + "被邀请入群"
        }
        
        if message.messageDetailModel?.systemType == .RmoveGroup {
            infoLb.text = names + "被踢出群"
        }
      
     
        if message.messageDetailModel?.systemType == .exitGroup {
            infoLb.text = names + "退出群聊"
        }
      
        timeLabel.text = message.messageDetailModel?.duration
        
        timeLabel.isHidden = !showTime
        timeLabel.text = RKChatToolkit.formatMessageDate(date: Date(timeIntervalSince1970: message.sendTimeLong/1000) as Date)
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubViews([timeLabel, infoLb])
        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(4)
            make.height.equalTo(20)
            make.centerX.equalToSuperview()
        }
        infoLb.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(timeLabel.snp_bottom)
            make.width.equalToSuperview().offset(-30)
            make.bottom.equalTo(-4)
        }
        
        self.selectionStyle = .none
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: false)

    }
    
    lazy var infoLb: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.textColor = UIColor(hex: 0x999999)
        label.numberOfLines = 0
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()
    
    lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .init(hex: 0x9F9F9F)
        return label
    }()
}
