//
//  RKAddressBookListView.swift
//  RKIM
//
//  Created by chzy on 2021/11/1.
//

import Foundation
import RKIBaseView
import RKIUtils
import Kingfisher
import UIKit
import RKIMCore

@objc protocol AddressBookListViewDeleagte: NSObjectProtocol {
    // MARK: - 呼叫按钮回调
   func click(_ index: Int)
    
    func singleClick(_ userId: String)
}

open class RKAddressBookListView: RKBaseTableView,UITableViewDataSource, UITableViewDelegate {
    
    weak var listViewDeleagte: AddressBookListViewDeleagte?
    // 创建特殊的联系人用于标记分组
    let contactInfoMarkUserId = "contactInfoMarkUserId"
    
    // 默认不展示分组
    var enableGroup = false
    
    // 默认不允许选择
    var enableSelected = false
    
    // 是否显示私聊按钮
    var showChatBtn = false
    
    // 联系人分组
    var contactGroups: [RKIMGroup?] = [] {
        didSet {
            adjustGroupChatViewIsExist()
            reloadData()
        }
    }
    
//
    // 联系人数据
    var dataList: [RKIMUser] = [RKIMUser()] {
        didSet {

            adjustGroupChatViewIsExist()

            if dataList.count > 0 {
                self.noNetworkView.isHidden = true
            }

            reloadData()
        }
    }
    
    func adjustGroupChatViewIsExist() {
        if enableGroup == true,
           contactGroups.count > 0, self.dataList.first?.userId != contactInfoMarkUserId{
            let contactGroupModel = RKIMUser()
            contactGroupModel.userId = contactInfoMarkUserId
            self.dataList.insert(contactGroupModel, at: 0)
        }
    }
    
    // 选中的联系人 [userId : ContactInfoModel]
    var selectedContactInfos: [String : RKIMUser] = [:]

    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        setupView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    open override func setupView()  {
        super.setupView()
        showsVerticalScrollIndicator = true
        self.rowHeight = 64
        self.dataSource = self
        self.delegate = self
        self.register(RKCustomListImageAccCell.self, forCellReuseIdentifier: NSStringFromClass(RKCustomListImageAccCell.classForCoder()))
        self.register(RKAddressBookListCell.self, forCellReuseIdentifier: NSStringFromClass(RKAddressBookListCell.classForCoder()))
        
        self.noNetworkView.isHidden = true
        self.addSubview(self.noNetworkView)
        self.noNetworkView.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.height.equalToSuperview()
        }
        
        let image = UIImage(named: "rk_empty_ab", aclass: self.classForCoder)
        self.emptyView.iconImageView.image = image
        self.emptyView.titleLable.text = "暂无联系人"
        self.emptyView.tipsLabel.text = "请联系后台管理员创建小组、联系人"
        
        self.emptyView.isHidden = true
        self.addSubview(self.emptyView)
        self.emptyView.snp.makeConstraints { (make) in
            make.width.height.equalToSuperview()
        }
    }
    
    open override func reloadData() {
        super.reloadData()
    }
    
    @objc public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataList.count
    }
    @objc public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.listViewDeleagte?.click(indexPath.row)
    }
    
    @objc public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let contactInfoModel = self.dataList[indexPath.row]
        if contactInfoModel.userId == contactInfoMarkUserId {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(RKCustomListImageAccCell.classForCoder())) as! RKCustomListImageAccCell
            
            cell.titleLabel.text = "\(LocalizedString("collaborationdesk_group")) (\(contactGroups.count))"
            let iconImage = UIImage(named: "book_cell_avatar_group_blue", aclass: self.classForCoder)
//            UIImage(named: "book_cell_avatar_group_blue")
            cell.iconImageView.image = iconImage
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(RKAddressBookListCell.classForCoder())) as! RKAddressBookListCell
            if showChatBtn {
                cell.singleClickAction = { [weak self] in
                    self?.listViewDeleagte?.singleClick(contactInfoModel.userId)
                }
            } else {
                cell.singleClickAction = nil
                cell.singleChatBtn.isHidden = true
            }
           
            cell.pickImageView.isHidden = !enableSelected
            
            let nameStr = contactInfoModel.realName
            if contactInfoModel.postName.count > 0 {
                // 判断是否需要走展示岗位
                let postName = "｜" + contactInfoModel.postName
                let nameAttribute = [NSAttributedString.Key.foregroundColor: UIColor(hex: 0x000000),
                                     NSAttributedString.Key.font: RKFont.font_mainText]
                let postNameAttribute = [NSAttributedString.Key.foregroundColor: UIColor(hex: 0x999999),
                                         NSAttributedString.Key.font: RKFont.font_nomalText]
                let attStr = NSMutableAttributedString(string: nameStr + postName)
                attStr.addAttributes(nameAttribute, range:NSRange.init(location: 0, length: nameStr.count))
                attStr.addAttributes(postNameAttribute, range: NSRange.init(location: nameStr.count, length: postName.count))
                
                cell.nameLabel.attributedText = attStr
                
            } else {
                cell.nameLabel.text = nameStr
            }

            
            if self.selectedContactInfos.keys.contains(contactInfoModel.userId) {
                cell.isChoosed = .choosed
            } else {
                cell.isChoosed = .unchoosed
            }
            
            if contactInfoModel.headPortrait.count > 0 {
                cell.avatarImageButton.kf.setImage(with: URL(string: contactInfoModel.headPortrait), for: .normal)
            } else {
                let avatarImage = UIImage(named: "book_avatar_bg_n", aclass: self.classForCoder)
                cell.avatarImageButton.setImage(avatarImage, for: .normal)
            }
            return cell
        }
    }
}

