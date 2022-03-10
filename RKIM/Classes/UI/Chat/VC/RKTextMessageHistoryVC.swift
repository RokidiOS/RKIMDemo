//
//  RKChatHistoryVC.swift
//  RKIM
//
//  Created by chzy on 2021/11/24.
//  聊天记录 控制器

import Foundation
import RKIUtils
import RKIBaseView
import RKIMCore
import WCDBSwift
import Kingfisher

class RKTextMessageHistoryVC: RKBaseViewController {
    
    // MARK: Properties
    //会话
    var groupID: String = ""
    
    //会话消息数据源
    private var messageSearchDataList = [RKIMMessage]()
    
    private lazy var searchTextField: UITextField = {
        let tf = UITextField()
        tf.backgroundColor = .init(hex: 0xF5F5F5)
        tf.layer.cornerRadius = 2
        tf.clearButtonMode = .whileEditing
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 46, height: 38)).then { leftView in
            _ = UIImageView(image: UIImage(named: "searchIcon", aclass: self.classForCoder)).then {
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
    
    private lazy var cancelButton:UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("取消", for: .normal)
        btn.setTitleColor(.init(hex: 0x1759F5), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16)
        btn.addTarget(self, action: #selector(leftBarButtonItemAction), for: .touchUpInside)
        return btn
    }()
    
    lazy var tipLabel:UILabel = {
        let label = UILabel()
        label.textColor = .init(hex: 0x999999)
        label.font = .systemFont(ofSize: 14)
        label.text = "请输入搜索内容"
        return label
    }()
    
    
    //列表
    lazy var tableView:RKBaseTableView  = {
        let tableView = RKBaseTableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(RKChatSearchHistoryCell.self, forCellReuseIdentifier: "cell")
        return tableView
    }()
    
    // MARK: liftCycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tipLabel.isHidden = false
        cancelButton.isHidden = false
    }
    
    override func setupView() {
        super.setupView()
        view.addSubViews([searchTextField, cancelButton, tipLabel, tableView])
        layoutInit()
    }
    
    func layoutInit() {
        
        searchTextField.snp.makeConstraints { make in
            make.top.equalTo(view).offset(12 + UI.SafeTopHeight)
            make.left.equalTo(20)
            make.right.equalTo(-54)
            make.height.equalTo(38)
        }
        
        cancelButton.snp.makeConstraints { make in
            make.centerY.equalTo(searchTextField)
            make.right.equalTo(-12)
        }
        
        tipLabel.snp.makeConstraints { make in
            make.top.equalTo(searchTextField.snp_bottom).offset(50)
            make.centerX.equalToSuperview()
        }
    
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchTextField.snp_bottom).offset(12)
            make.left.right.bottom.equalToSuperview()
        }
        
    }
    
    // MARK: Action
    
    @objc private func textFieldDidChange() {
        let inputed = searchTextField.text?.count ?? 0 > 0
        
//        tipLabel.isHidden = inputed
//
//        //聊天记录搜索
//        messageSearchDataList = JCCloudDatabase.searchMessage(searchTextField.text ?? "", contentTypes: ["Text"], conversationId: conversation._id)
//        tableView.reloadData()
        guard let text = searchTextField.text else { return  }
        loadData(text)
    }
    
    func loadData(_ queryString: String) {
        // 本地数据库查询
        let contentText = Expression(with: Column(named: "messageDetail")).like("%\(queryString)%") //消息内容
        let sameGroup = Expression(with: Column(named: "receiveGroup")).like(groupID)
        RKIMDBManager.queryObjects(RKIMMessage.self, where: contentText && sameGroup, orderBy: [ RKIMMessage.Properties.sendTimeLong.asOrder(by: .ascending)]) { localMessages in
            self.messageSearchDataList = localMessages
            self.tableView.reloadData()
        }
        
        RKIMManager.share.searchHistoryMessage(recieverGroup: groupID, messageInfo: queryString, messageType: 1, pageIndex: 1, pageSize: 10000, sendTimeLongStart: nil, sendTimeLongEnd: nil) { _, _, messageList in
            guard let messageList = messageList else { return }
            self.messageSearchDataList = messageList
            self.tableView.reloadData()
        }
    }
}


extension RKTextMessageHistoryVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return messageSearchDataList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.register(RKChatSearchHistoryCell.self, forCellReuseIdentifier: "RKChatSearchHistoryCell")
        let cell = tableView.dequeueReusableCell(withIdentifier: "RKChatSearchHistoryCell", for: indexPath)
        let model = messageSearchDataList[indexPath.row]
        let url = model.senderAvator
        let image = UIImage(named: "default_avatar", aclass: self.classForCoder)
        cell.imageView?.kf.setImage(with: URL(string: url), placeholder: image)
        cell.textLabel?.text = model.messageDetailModel?.content
        cell.detailTextLabel?.text = RKChatToolkit.formatMessageDate(date: Date(timeIntervalSince1970: model.sendTimeLong/1000) as Date)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        view.endEditing(true)
        let locationMessage = messageSearchDataList[indexPath.row]
        let chatDetailVC = RKChatDetailVC()
        chatDetailVC.groupId = groupID
        chatDetailVC.locationMessage = locationMessage
        navigationController?.pushViewController(chatDetailVC, animated: true)
    }
}
