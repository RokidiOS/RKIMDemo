//
//  RKGroupList.swift
//  RKIM
//
//  Created by chzy on 2021/11/2.
//  群组信息tableview

import Foundation
import RKBaseView
import RKIMCore

protocol AddressBookGroupListViewDeleagte: NSObjectProtocol {
    // MARK: - 呼叫按钮回调
    func cellCallButtonAction(_ index: Int)
}

class RKAddressBookGroupListView: RKBaseTableView {
    
    weak var listViewDelegate: AddressBookGroupListViewDeleagte?
    
    // 联系人分组
    var contactGroups: [RKIMGroup] = [] {
        didSet {
            self.reloadData()
        }
    }
    
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    override func setupView()  {
        super.setupView()
        
        self.rowHeight = 64
        self.dataSource = self
        
        self.register(RKAddressBookGroupListCell.self, forCellReuseIdentifier: NSStringFromClass(RKAddressBookGroupListCell.classForCoder()))
    }
    
    @objc func cellCallButtonAction(_ sender: UIButton) {
        listViewDelegate? .cellCallButtonAction(sender.tag)
    }
}

extension RKAddressBookGroupListView: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contactGroups.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(RKAddressBookGroupListCell.classForCoder())) as! RKAddressBookGroupListCell
        
        let contactGroupModel = self.contactGroups[indexPath.row]
        
        cell.nameLabel.text = contactGroupModel.groupName
        cell.memeberLabel.text = "共\(contactGroupModel.totalAccountNum)人"
        let iconImage = UIImage(named: "book_cell_avatar_group_white", aclass: self.classForCoder)
        cell.avatarImageView.image = iconImage
        
        cell.callButton.tag = indexPath.row
        cell.callButton.addTarget(self, action: #selector(cellCallButtonAction(_:)), for: .touchUpInside)
        
        return cell
    }
}
