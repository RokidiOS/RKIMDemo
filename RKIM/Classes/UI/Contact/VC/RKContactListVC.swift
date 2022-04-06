//
//  RKContactListVC.swift
//  RKIM
//
//  Created by chzy on 2021/11/1.
//  联系人列表控制器

import Foundation
import RKIHandyJSON
import RKIBaseView
import RKIUtils
import RKILogger
import WCDBSwift
import RKIMCore
import MapKit

open class RKContactListVC: UIViewController {
    // 联系人列表
    var selfContacts: [RKIMUser] = [RKIMUser()]{
        didSet {
            self.addressBookListView.dataList = selfContacts
        }
    }
    // 群组列表
    var selfGroupModel: [RKIMGroup] = [RKIMGroup()]  {
        didSet {
            self.addressBookListView.contactGroups = selfGroupModel
        }
    }
    
    var isChoosed = false {
        didSet {
                configNavigationbarItems()
        }
    }
        
    open override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = .bottom
        navigationItem.title = "联系人"
        addressBookListView.delegate = self
        view.addSubview(searchTextField)
        searchTextField.snp.makeConstraints { make in
            make.top.equalTo(10)
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.centerX.equalToSuperview()
            make.height.equalTo(38)
        }

        
        view.addSubview(addressBookListView)
        addressBookListView.snp.makeConstraints { make in
            make.bottom.left.right.equalToSuperview()
            make.top.equalTo(searchTextField.snp_bottom).offset(10)
        }
        loadGroupData()
        loadContactData()
    }
    
    // 定制导航栏右侧按钮
    func configNavigationbarItems() {
        if isChoosed {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: LocalizedString("custom_cancel"), style: .plain, target: self, action: #selector(resetNavItemAction))
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: LocalizedString("custom_create_group"), style: .plain, target: self, action: #selector(createAction))
        }
    }
    
    @objc func resetNavItemAction() {
        navigationItem.rightBarButtonItem = nil
        navigationItem.leftBarButtonItem = nil
        addressBookListView.enableSelected = false
        addressBookListView.selectedContactInfos.removeAll()
        addressBookListView.reloadData()
    }
    
    @objc func createAction() {
       let users = Array(self.addressBookListView.selectedContactInfos.keys)
        RKIMManager.share.createGroup(groupName: "新群组", ownerId: nil, ownerJoinFlag:true, groupConfig: "", userList: users, compelet: { isSuccess, errorMessage, result in
            if isSuccess {
                RKToast.show(withText: "创建群组成功", duration: 1, in: self.view)
                self.resetNavItemAction()
            } else {
                RKToast.show(withText: "创建群组失败", duration: 1, in: self.view)
            }
        })
    }
    
    @objc private func textFieldDidChange() {
        searchText = (searchTextField.text ?? "").trimmingCharacters(in: .whitespaces)
        searchedContactList = selfContacts.filter {
            return $0.realName.contains(searchText)
        }
        if searchedContactList.isEmpty, searchText.isEmpty {
            addressBookListView.dataList = selfContacts
        } else {
            addressBookListView.dataList = searchedContactList
        }
        //聊天记录搜索
        addressBookListView.reloadData()
    }
    
    // 加载群组信息
    func loadGroupData() {
        RKIMDBManager.queryObjects(RKIMGroup.self, where: RKUserCenter.userConCondition()) { groupModel in
            self.selfGroupModel = groupModel
        }
        
        RKIMManager.share.groupList { isSuccess, errorMessage, groups in
            guard let groups = groups else { return }
            self.selfGroupModel = groups
            RKIMDBManager.dbAddObjects(groups)
        }
    }
    
    // 加载联系人列表
    func loadContactData() {
      
        RKIMDBManager.queryObjects(RKIMUser.self, where: RKUserCenter.userConCondition(), orderBy:[ RKIMUser.Properties.username.asOrder(by: .ascending)]) { contacts in
            self.selfContacts = contacts
        }
        
        RKIMManager.share.contactList { isSuccess, errorMessage, contacts in
            if isSuccess {
                guard let contacts = contacts else { return }
                self.selfContacts = contacts
                RKIMDBManager.dbAddObjects(contacts)
                
            } else {
                guard let errorMessage = errorMessage else { return }
                RKToast.show(withText: "\(errorMessage)")
            }
            
        }
    
    }
    
    lazy var addressBookListView: RKAddressBookListView = {
        let adView =  RKAddressBookListView(frame: view.bounds, style: .plain)
        adView.enableGroup = true
        return adView
    }()
    private lazy var searchedContactList: [RKIMUser] = []
    private lazy var searchText = ""
    private lazy var searchTextField: UITextField = {
        let tf = UITextField()
        tf.delegate = self
        tf.placeholder = "请输入搜索内容..."
        tf.backgroundColor = .init(hex: 0xF5F5F5)
        tf.layer.cornerRadius = 2
        
        tf.clearButtonMode = .whileEditing
        
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 46, height: 38)).then { leftView in
            _ = UIImageView(image: UIImage(named: "searchIcon")).then {
                leftView.addSubview($0)
                $0.frame = CGRect(x: 16, y: 12, width: 14, height: 14)
            }
        }
        
        tf.leftView = leftView
        tf.leftViewMode = .always
        
        tf.returnKeyType = .search
        tf.enablesReturnKeyAutomatically = true
        
        tf.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        return tf
    }()
    
}

extension RKContactListVC: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let contactInfoModel = addressBookListView.dataList[indexPath.row]
        if contactInfoModel.userId == addressBookListView.contactInfoMarkUserId {
            // 群组
            let addressBookGroupVC = RKAddressBookGroupViewController()
            addressBookGroupVC.contactGroups = selfGroupModel
            addressBookGroupVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(addressBookGroupVC, animated: true)
            
        } else {
            // 离线状态不可选取
//            guard contactInfoModel.status == 1 else {
//                return
//            }
            
            guard self.addressBookListView.selectedContactInfos.keys.count < 15 else {
                RKToast.show(withText: "您最多可选择15个人发起协作", in: view)
                return
            }
            
            if self.addressBookListView.selectedContactInfos.keys.contains(contactInfoModel.userId) {
                self.addressBookListView.selectedContactInfos.removeValue(forKey: contactInfoModel.userId)
            } else {
                self.addressBookListView.selectedContactInfos[contactInfoModel.userId] = contactInfoModel
            }
            
            addressBookListView.enableSelected = true
            if !self.addressBookListView.selectedContactInfos.isEmpty {
                isChoosed = true
                configNavigationbarItems()
            } else {
                isChoosed = false
            }
            addressBookListView.reloadData()
        }
    }
}

extension RKContactListVC: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchTextField.resignFirstResponder()
        addressBookListView.dataList = selfContacts
        return true
    }
 
}
