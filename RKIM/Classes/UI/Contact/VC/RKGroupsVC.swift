//
//  RKGroupsVC.swift
//  RKIM
//
//  Created by chzy on 2021/11/2.
//  群组列表控制器

import Foundation
import RKIHandyJSON
import RKIBaseView
import RKIUtils
import RKIMCore

class RKAddressBookGroupViewController: RKBaseViewController {
    
    // 联系人分组
    var contactGroups: [RKIMGroup] = [] {
        didSet {
            addressBookGroupListView.reloadData()
        }
    }
    
    lazy var addressBookGroupListView: RKAddressBookGroupListView = {
        RKAddressBookGroupListView.init(frame: .zero, style: .plain)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = LocalizedString("collaborationdesk_group")
    }
    
    override func setupView() {
        super.setupView()
        
        self.addressBookGroupListView.delegate = self
        self.addressBookGroupListView.listViewDelegate = self
        self.addressBookGroupListView.contactGroups = contactGroups
        self.view.addSubview(self.addressBookGroupListView)
        self.addressBookGroupListView.snp.makeConstraints { (make) in
            make.top.left.width.height.equalToSuperview()
        }
    }
}

extension RKAddressBookGroupViewController: AddressBookGroupListViewDeleagte {
    
    func cellCallButtonAction(_ index: Int) {
        
        let contactGroupModel = contactGroups[index]
        
        var selectedContactInfos: [RKIMUser] = []
        
        for item in contactGroupModel.userList {
            if !item.isSelf {
                selectedContactInfos.append(item)
            }
        }
        
        guard selectedContactInfos.count > 0 else {
            RKToast.show(withText: "没有联系人在线")
            return
        }
        
        guard selectedContactInfos.count < 15 else {
            RKToast.show(withText: "协作模块 todo")
            #warning("TODO 协作页面")
            return
        }

    }
}

extension RKAddressBookGroupViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let userList = contactGroups[indexPath.row].userList
        let groupDetailVC = RKGroupdDetailVC()
        groupDetailVC.dataList = userList
        groupDetailVC.groupID = contactGroups[indexPath.row].groupId
        groupDetailVC.loadGourpUser(contactGroups[indexPath.row].groupId)
        navigationController?.pushViewController(groupDetailVC, animated: true)
    }
}
