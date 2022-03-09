//
//  RKInviteVC.swift
//  RKIM
//
//  Created by chzy on 2022/2/17.
//  邀请入群

import Foundation
import RKIMCore
import RKBaseView

class RKInviteVC: UIViewController {
    var groupID: String?
    var selfContacts: [RKIMUser] = [RKIMUser()]{
        didSet {
            self.addressBookListView.dataList = selfContacts
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "邀请成员"
        addressBookListView.delegate = self
        view.addSubview(addressBookListView)
        addressBookListView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
        loadContactData()
        navigationConfig()
    }
    
    func navigationConfig() {
        let rightBarButtonItem = UIBarButtonItem(title: "邀请", style: .done, target: self, action: #selector(invitedAction))
        self.navigationItem.rightBarButtonItem = rightBarButtonItem
    }
    
    
    lazy var addressBookListView: RKAddressBookListView = {
        let adView =  RKAddressBookListView(frame: view.bounds, style: .plain)
        adView.enableGroup = true
        return adView
    }()
    
    func loadContactData() {
      
        guard let groupID = groupID else { return }
        RKIMManager.share.groupMemberList(groupID: groupID) { isSuccess, errorMessage, alreadyContacts in
            if isSuccess {
                self.queryallMembers { contacts in
                    guard let alreadyContacts = alreadyContacts else { return }
                    var tpContact = contacts
                    for pAlready in alreadyContacts {
                        tpContact.removeAll { pModel in
                            pModel.userId == pAlready.userId
                        }
                    }
                    self.selfContacts = tpContact
                }
            }
        }
        
    }
    
    func queryallMembers(_ complete:@escaping ([RKIMUser]) ->Void) {
        RKIMDBManager.queryObjects(RKIMUser.self, where: RKUserCenter.userConCondition(), orderBy:[ RKIMUser.Properties.username.asOrder(by: .ascending)]) { contacts in
            complete(contacts)
        }
    }
}


extension RKInviteVC: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let contactInfoModel = addressBookListView.dataList[indexPath.row]
         
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
        addressBookListView.reloadData()
            
    }
//    {  tableView.deselectRow(at: indexPath, animated: true)
//        let contact = selfContacts[indexPath.row]
//
//        let alerControll = UIAlertController(title: "温馨提示", message: "您将邀请\(contact.username) 进入群聊", preferredStyle: .alert)
//        let doneAction = UIAlertAction(title: "确定", style: .default) { _ in
//
//        }
//        let cancelAction = UIAlertAction(title: "取消", style: .destructive) { _ in
//            alerControll.dismiss(animated: true, completion: nil)
//        }
//        alerControll.addAction(doneAction)
//        alerControll.addAction(cancelAction)
//        present(alerControll, animated: true, completion: nil)
//
//    }
    
   @objc func invitedAction() {
       
       guard let groupID = groupID else { return }
       let invitedUsers = addressBookListView.selectedContactInfos.keys.map{$0}
       if invitedUsers.isEmpty {
           RKToast.show(withText: "还未选择人员哦", in: view)
           return
       }
       let sureBlock:() ->Void = {
           RKIMManager.share.addGroupUsers(groupId: groupID, userList: invitedUsers) { isSuccess, errorMessage, result in
                if isSuccess {
                    RKToast.show(withText: "邀请成功", in: self.view)
                    self.addressBookListView.selectedContactInfos.removeAll()
                    self.loadContactData()
                } else {
                    RKToast.show(withText: errorMessage, in: self.view)
                }
           }
       }
       
       let alerControll = UIAlertController(title: "温馨提示", message: "您将邀请选中用户进入群聊", preferredStyle: .alert)
       let doneAction = UIAlertAction(title: "确定", style: .default) { _ in
           sureBlock()
       }
       let cancelAction = UIAlertAction(title: "取消", style: .destructive) { _ in
           alerControll.dismiss(animated: true, completion: nil)
       }
       alerControll.addAction(doneAction)
       alerControll.addAction(cancelAction)
       present(alerControll, animated: true, completion: nil)
   
        
    }
    
}
