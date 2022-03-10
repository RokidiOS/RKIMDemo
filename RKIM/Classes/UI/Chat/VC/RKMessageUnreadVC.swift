//
//  RKMessageUnreadVC.swift
//  RKIM
//
//  Created by chzy on 2022/2/9.
//

import RKIBaseView
import RKIMCore
import Kingfisher
import Foundation

class RKMessageUnreadVC: RKBaseViewController {
    
    static func show(_ groupId: String, _ messageId: String) -> UINavigationController {
        let unreadVC = RKMessageUnreadVC()
        unreadVC.messageId = messageId
        unreadVC.groupId = groupId
        let naVC = RKBaseNavigationController(rootViewController: unreadVC)
        return naVC
    }
    var messageId: String = ""
    var groupId: String = ""
    var readDataSource = [String]()//已读列表
    var unreadDataSource = [String]()//未读列表
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "消息接收人列表"
        let leftItem = UIBarButtonItem(image: UIImage(named: "close", aclass: self.classForCoder), landscapeImagePhone: nil, style: .done, target: self, action: #selector(dismss))
        navigationItem.leftBarButtonItem = leftItem
        loadData()
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
     }
    
    @objc private func dismss() {
        dismiss(animated: true, completion: nil)
    }
    
    private func loadData() {
        RKIMManager.share.messageUserReadList(groupId: groupId, messageId: messageId) { isSuccess, errorMessage, result in
            if isSuccess {
                if let result = result as? [String: [String]] {
                    self.readDataSource = result["readUserList"] ?? []
                    self.unreadDataSource = result["unReadUserList"] ?? []
//                    self.userInstead(&self.readDataSource)
//                    self.userInstead(&self.unreadDataSource)
                    self.userInstead(self.readDataSource) {[weak self] array in
                        self?.readDataSource = array
                    }
                    self.userInstead(self.unreadDataSource) {[weak self] array in
                        self?.unreadDataSource = array
                    }

                }
            } else {
                RKToast.show(withText: errorMessage, in: self.view)
            }
        }
    }
    
    private func userInstead(_ userIds: [String], compelet: @escaping ([String]) -> Void){
        var tpArray = [String]()
        for id in userIds {
            DBHelper.asyUser(id) { model in
                guard let model = model else { return }
                tpArray.append(model.realName)
                if tpArray.count == userIds.count {
                    compelet(tpArray)
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
          
        }
    }
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        
        return tableView
    }()
}

extension RKMessageUnreadVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: "cell")
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
//        cell.imageView?.kf.setImage(with: URL(string: ""))
        if indexPath.section == 0 {
            cell.textLabel?.text = unreadDataSource[indexPath.row]
            
        } else {
            cell.textLabel?.text = readDataSource[indexPath.row]
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "未读人数\(unreadDataSource.count)"
        } else {
            return "已读人数\(readDataSource.count)"
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return unreadDataSource.count
        } else {
            return readDataSource.count
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
}
