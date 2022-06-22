//
//  RKGroupDetailVC.swift
//  RKIM
//
//  Created by chzy on 2021/11/2.
//

import Foundation
import RKIBaseView
import RKIHandyJSON
import RKIMCore
import UIKit
import WCDBSwift

enum GroupSelectAction: String {
    case members = "群组联系人"
    case remove = "移除群成员"
    case reOwner = "移交群组"
}
class RKGroupdDetailVC: RKBaseViewController {
    var action:GroupSelectAction = .members {
        didSet {
            self.title = action.rawValue
        }
    }
    var groupID: String?
    var dataList: [RKIMUser] = [RKIMUser()] {
        didSet {
            addressBookListView.dataList = dataList
        }
    }
    
    open override func setupView() {
        super.setupView()
        view.addSubview(addressBookListView)
        addressBookListView.listViewDeleagte = self
        addressBookListView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
        DispatchQueue.main.async {
            if self.action != .members {
                UIAlertView(title: "温馨提示", message: "点击对应成员 \(self.action.rawValue)", delegate: nil, cancelButtonTitle: "我知道了").show()
            }
        }
        guard let groupID = groupID else {
            return
        }
        loadGourpUser(groupID)
    }

    func loadGourpUser(_ groupId: String) {
        RKIMManager.share.groupMemberList(groupID: groupId) { isSuccess, errorMessage, contacts in
            guard let contacts = contacts else { return }
            #warning("TODO")
//            self.dataList = contacts
        }
    }
    
    var addressBookListView: RKAddressBookListView = {
        let adView = RKAddressBookListView(frame: CGRect.zero, style: .plain)
        adView.enableGroup = false
        adView.enableSelected = false
        return adView
    }()
    
}

extension RKGroupdDetailVC: AddressBookListViewDeleagte {
    func singleClick(_ userId: String) {
    
    }
    
    func click(_ index: Int) {
        guard index < dataList.count else {
            RKToast.show(withText: "操作失败", in:view)
            guard let groupID = groupID else { return }
            loadGourpUser(groupID)
            return
        }
        
        if self.action == .members {
            
            let infoVC =  RKUserDetailInfoViewController()
            infoVC.info = dataList[index]
            self.navigationController?.pushViewController(infoVC, animated: true)
        } else {
//            if dataList[index].isSelf {
//                RKToast.show(withText: "不能对自己进行操作", in:view)
//                return
//            }
            let userId = dataList[index].userId
            let alerControll = UIAlertController(title: "温馨提示", message: "您将\(action.rawValue)", preferredStyle: .alert)
            let doneAction = UIAlertAction(title: "确定", style: .default) { _ in
                self.takeAction(userId)
            }
            let cancelAction = UIAlertAction(title: "取消", style: .cancel) { _ in
                alerControll.dismiss(animated: true, completion: nil)
            }
            alerControll.addAction(cancelAction)
            alerControll.addAction(doneAction)
            present(alerControll, animated: true, completion: nil)

        }
    }
    
    
    func takeAction(_ userId: String) {
        guard let groupID = groupID else {
            RKToast.show(withText: "群ID缺失", in:view)
            return
        }
        
        if action == .reOwner {
            RKIMManager.share.updateGroupInfo(groupId: groupID, ownerId: userId) { isSuccess, errorMessage, result in
                if isSuccess {
                    DBHelper.asyGroup(groupID) { model in
                        if let group = model {
                            group.ownerId = userId
                            RKIMDBManager.dbAddObjects([group])
                        }
                    }
                    RKToast.show(withText:"任命群主成功")
                    self.navigationController?.popViewController(animated: true)
                    self.loadGourpUser(groupID)
                } else {
                    RKToast.show(withText:errorMessage)
                }
            }
        } else if action == .remove {
            RKIMManager.share.rmoveGroupUsers(groupId: groupID, userList: [userId]) { isSuccess, errorMessage, result in
                if isSuccess {
                    RKToast.show(withText:"移除群成员成功")
                    self.loadGourpUser(groupID)
                } else {
                    RKToast.show(withText:errorMessage)
                }
                
            }
        }
    }
}
