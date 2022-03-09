//
//  RKChatListVC.swift
//  Alamofire
//
//  Created by chzy on 2021/11/2.
//  会话消息列表

import Foundation
import RKBaseView
import RKLogger
import UIKit
import Then
import RKHandyJSON
import RKIMCore
import WCDBSwift

open class RKChatListVC: RKBaseViewController {
 
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    
    open override func viewDidLoad() {
       super.viewDidLoad()
       title = "消息"
       RKIMManager.share.addDelegate(newDelegate: self)
       loadData()
       setupRightNavBarItem()
    }
    
    func loadData(_ isNeedLoadNet: Bool = true) {

        RKIMDBManager.queryObjects(RKIMGroup.self, where: RKUserCenter.userConCondition()) { groups in
            self.groupList = groups
            self.tableView.emptyView.isHidden = groups.count > 0
            self.resortRefreshList()
        }
        
        if isNeedLoadNet {
            RKIMManager.share.groupList { isSuccess, errorMessage, groups in
                guard let groups = groups else { return }//
                self.groupList = groups
                RKIMDBManager.dbAddObjects(groups)
                self.tableView.emptyView.isHidden = groups.count > 0
                self.resortRefreshList()
                
                if let detailVC = self.detailVC {
                    for group in groups {
                        if group.groupId == detailVC.groupId {
                            detailVC.title = group.groupName
                            break
                        }
                    }
                }
                
            }
        }
    }
    
    open override func setupView() {
        super.setupView()
        view.addSubview(tableView)
        view.addSubview(searchTextField)
        searchTextField.snp.makeConstraints { make in
            make.top.equalTo(10)
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.centerX.equalToSuperview()
            make.height.equalTo(38)
        }
       
       tableView.snp.makeConstraints { make in
           make.top.equalTo(searchTextField.snp_bottom).offset(10)
           make.bottom.left.right.equalTo(view)
       }
    }
    
    open override func setupLeftNavBarItem() {}
    
    open override func setupRightNavBarItem() {
        let logOutItem = UIBarButtonItem(title: "退出登录", style: .plain, target: self, action: #selector(logoutAction))
        navigationItem.rightBarButtonItem = logOutItem
    }
    
    @objc func logoutAction() {
        let alertVC = UIAlertController(title: "退出登录", message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "取消", style: .default) { _ in
            alertVC.dismiss(animated: true, completion: nil)
        }
        let doneAction = UIAlertAction(title: "确定", style: .destructive) { _ in
            LogoutHelper.logoutBlock()
        }
        alertVC.addAction(cancelAction)
        alertVC.addAction(doneAction)
        present(alertVC, animated: true, completion: nil)
    }
    
    @objc private func textFieldDidChange() {
        searchText = (searchTextField.text ?? "").trimmingCharacters(in: .whitespaces)
        searchedChatList = groupList.filter {
            return $0.groupName.contains(searchText)
        }
        
        //聊天记录搜索
        tableView.reloadData()
    }
    
    private func queryGroupList() {
        
    }
    
    private func setGroupMembersIconList() {
        resortRefreshList()
    }
    
    ///排序刷新列表
    private func resortRefreshList() {
        groupList = groupList.sorted { (s1: RKIMGroup, s2: RKIMGroup) in
            let message1 = s1.lastMessage
            let message2 = s2.lastMessage
            guard let s1sendTimeLong = message1?.sendTimeLong else { return false }
            guard let s2sendTimeLong = message2?.sendTimeLong else { return false }
            if Int(s1sendTimeLong) > Int(s2sendTimeLong) {
                return true
            }
            return false
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    weak var detailVC: RKChatDetailVC?
    private static let CellReuseIdentifier = "cell"
    lazy var groupList: [RKIMGroup] = []
    private lazy var searchedChatList: [RKIMGroup] = []
    private lazy var searchText = ""
    private lazy var searchTextField = UITextField().then {
   
        $0.delegate = self
        $0.placeholder = "请输入搜索内容..."
        $0.backgroundColor = .init(hex: 0xF5F5F5)
        $0.layer.cornerRadius = 2
        
        $0.clearButtonMode = .whileEditing
        
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 46, height: 38)).then { leftView in
            _ = UIImageView(image: UIImage(named: "searchIcon")).then {
                leftView.addSubview($0)
                $0.frame = CGRect(x: 16, y: 12, width: 14, height: 14)
            }
        }
        
        $0.leftView = leftView
        $0.leftViewMode = .always
        
        $0.returnKeyType = .search
        $0.enablesReturnKeyAutomatically = true
        
        $0.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    //列表
    public lazy var tableView = RKBaseTableView().then {
        view.addSubview($0)        
        $0.delegate = self
        $0.dataSource = self
        
        $0.emptyView.iconImageView.image = UIImage(named: "rk_empty_sr")
        $0.emptyView.titleLable.text = "暂无内容"

        $0.register(RKChatListCell.self, forCellReuseIdentifier: RKChatListVC.CellReuseIdentifier)
    }
}


//MARK: - textfield代理
extension RKChatListVC: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchTextField.resignFirstResponder()
        
        return true
    }
}

//MARK: - tableview代理
extension RKChatListVC: UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  searchText.count > 0 ? searchedChatList.count : groupList.count
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: RKChatListVC.CellReuseIdentifier, for: indexPath) as! RKChatListCell
        let list = searchText.count > 0 ? searchedChatList : groupList
        if list.count > indexPath.row {
            cell.setModel(list[indexPath.row])
        }
        return cell
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchTextField.endEditing(true)
    }
}

extension RKChatListVC: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let chatDetailVC = RKChatDetailVC()
        let group = groupList[indexPath.row]
        group.unReadCount = 0
        RKIMDBManager.dbAddObjects([group])
        tableView.reloadData()
        
        detailVC = chatDetailVC
        detailVC?.refreshBlock = {[weak self]
            isSuccess in
            if isSuccess {
                self?.loadData(isSuccess)
            }
        }
        chatDetailVC.title = group.groupName
        chatDetailVC.groupId = group.groupId
        chatDetailVC.groupInfo = group
        chatDetailVC.groupMemberCount = group.userList.count
        navigationController?.pushViewController(chatDetailVC, animated: true)
    }
}

extension RKChatListVC: RKIMDelegate {
    
    public func identString() -> String {
       return "RKChatListVC"
    }
    
    public func message(didReceiveSystemMessage message: RKIMMessage) {
        if message.messageType == .system {
            self.loadData()
        }
    }
    
    public func message(didReceiveNormalMessage message: RKIMMessage) {
        DispatchQueue.global().async {
            if message.messageType == .unread { return }
            let groupModel = self.groupList.filter {$0.groupId == message.receiveGroup}.first
            guard let groupModel = groupModel else { //  没有群聊请求服务器
                self.loadData()
                return
            }
            groupModel.lastMessage = message
            groupModel.unReadCount += 1
            if let detailGroupID = self.detailVC?.groupId {
                if detailGroupID == message.receiveGroup {
                    groupModel.unReadCount = 0
                }
            }
            RKIMDBManager.dbAddObjects([groupModel])
            self.resortRefreshList()
            
        }
    }
    
    public func didOpen() {
        
    }
    
    public func didFail(WithError error: Swift.Error) {
        
    }
    
    public func didClose(code: Int, reason: String?) {
        
    }
    
    
}
