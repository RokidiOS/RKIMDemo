//
//  RKChatSettingVC.swift
//  RKIM
//
//  Created by chzy on 2021/11/23.
//  群信息设置 vc

import Foundation
import RKIMCore
import RKIBaseView
import RKIUtils
import UIKit
import Kingfisher
import WCDBSwift

class RKChatSettingVC: RKBaseViewController {
    enum rkSettingType: String {
        case member = "member"
        case chatHistory = "chatHistory"
        case board = "board"
    }
    
    var groupID: String!
    var groupInfo = RKIMGroup() {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }
    
    var cellTyps: [rkSettingType] = [.member, .chatHistory, .board]
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "群聊信息"
        registerCells()
        loadData()
    }
    
    func registerCells() {
        for type in cellTyps {
            if type == .member {
                tableView.register(RKChatSettingMemberCell.classForCoder(), forCellReuseIdentifier: type.rawValue)
            } else if type == .chatHistory {
                tableView.register(RKChatHistoryCell.classForCoder(), forCellReuseIdentifier: type.rawValue)
            } else if type == .board {
                tableView.register(RKChatBoardCell.classForCoder(), forCellReuseIdentifier: type.rawValue)
            }
        }

        
    }
    override func setupView() {
        super.setupView()
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
    }
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: UITableView.Style.grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = .clear
        tableView.backgroundColor = .init(hex: 0xF8F9FB)
        return tableView
    }()
    
    // MARK:  loadData
    func loadData() {
        DBHelper.asyGroup(groupID) { model in
            if let info = model {
                self.groupInfo = info
            }
        }
    }
    
    func showTextView() {
        let editVC = RKGroupNoticeEditVC()
        editVC.groupInfo = groupInfo
        navigationController?.pushViewController(editVC, animated: true)
    }
}

extension RKChatSettingVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return cellTyps.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let type = cellTyps[indexPath.section]
        if type == .member {
         return RKChatSettingMemberCell.heightForCell(groupInfo)
        } else if type == .chatHistory {
            return RKChatHistoryCell.heightForCell(groupInfo)
        } else if type == .board {
//            return RKChatBoardCell.heightForCell(groupInfo)
            return UITableView.automaticDimension
        }
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellTyps[indexPath.section].rawValue, for: indexPath)
        if let cell = cell as? RKChatSettingCell {
            cell.groupInfo = groupInfo
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch cellTyps[indexPath.section] {
        case .chatHistory:
            let chatHistoryVC = RKTextMessageHistoryVC()
             chatHistoryVC.groupID = groupID
             navigationController?.pushViewController(chatHistoryVC, animated: true)
        case .member:
            break
        case .board:
            showTextView()
        }
   
    
    }
    
}

class RKChatSettingCell: UITableViewCell {
    var groupInfo: RKIMGroup = RKIMGroup() {
        didSet {
           reloadCell(groupInfo)
        }
    }
    open func reloadCell(_ model: RKIMGroup) {
        
    }
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class func heightForCell(_ groupInfo: RKIMGroup) -> CGFloat {
        return 100
    }
}

// MARK:  成员管理
class RKChatSettingMemberCell: RKChatSettingCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubViews([ titleLabel, moreButton, collectionView])
        initlayout()
    }

    override class func heightForCell(_ groupInfo: RKIMGroup) -> CGFloat {
        var height = 40.0
        let totalCount = groupInfo.userList.count + 1
        var lines = totalCount / 7
        let hasRemainder = totalCount % 7 != 0
        if hasRemainder {
            lines += 1
        }
        height = Double(lines) * perWidth + Double(lines + 1) * perGap() + height
        return height
    }
    
    override func reloadCell(_ model: RKIMGroup) {
        collectionView.reloadData()
        moreButton.setTitle("共\(model.userList.count)人 ", for: .normal)
    }
    
    static let perWidth = 40.0
    class func perGap() -> CGFloat {
        let gap = (Double(UI.ScreenWidth) - perWidth * 7) / 8.0
        return gap
    }
    
    func initlayout() {

        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(15)
            make.height.equalTo(40)
            make.top.right.equalTo(self)
        }
        
        moreButton.snp.makeConstraints { make in
            make.top.bottom.equalTo(titleLabel)
            make.right.equalTo(-15)
            make.width.greaterThanOrEqualTo(60)
        }
        
        collectionView.snp.makeConstraints { make in
            make.left.bottom.right.equalTo(self)
            make.top.equalTo(titleLabel.snp_bottom)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let imageSize: CGSize = moreButton.imageView!.frame.size
        let titleSize: CGSize = moreButton.titleLabel!.frame.size
        moreButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageSize.width, bottom: 0, right: imageSize.width)
        moreButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: titleSize.width, bottom: 0, right: -titleSize.width)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "群成员"
        label.textColor = .init(hex: 0x1A1A1A)
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    lazy var moreButton: UIButton = {
        let btn = UIButton()
        let image = UIImage(named: "right_arrow", aclass: self.classForCoder)
        btn.setImage(image, for: .normal)
        btn.addTarget(self, action: #selector(showMoreUserInfo), for: .touchUpInside)
//        btn.backgroundColor = .red
        btn.setTitle("1", for: .normal)
        btn.setTitleColor(.init(hex: 0x909090), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16)
        btn.setContentHuggingPriority(.required, for: .horizontal)
        btn.setContentCompressionResistancePriority(.required, for: .horizontal)
        return btn
    }()
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: RKChatSettingMemberCell.perWidth, height: RKChatSettingMemberCell.perWidth)
        let gap = RKChatSettingMemberCell.perGap()
        layout.minimumLineSpacing = gap
        layout.minimumInteritemSpacing = gap
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInset = UIEdgeInsets(top: 10, left: gap, bottom: 10, right: gap)
        return collectionView
    }()
    
    class RKChatSettingCollectionCell: UICollectionViewCell {
        override init(frame: CGRect) {
            super.init(frame: frame)
            setupUI()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func setupUI() {
            contentView.addSubview(imageView)
            imageView.backgroundColor = UIColor.clear
            imageView.snp.makeConstraints { make in
                make.edges.equalTo(contentView)
            }
        }
        
        lazy var imageView: UIImageView = {
            let imageView = UIImageView()
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 20
            return imageView
        }()
    }

    @objc func showMoreUserInfo() {
        
    }
}

// MARK: 查看聊天记录

class RKChatHistoryCell: RKChatSettingCell {
    override class func heightForCell(_ groupInfo: RKIMGroup) -> CGFloat {
        return 54
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubViews([infoLabel, arrowImageView])
        initlayout()
    }
    
    func initlayout() {
        infoLabel.snp.makeConstraints { make in
            make.left.equalTo(15)
            make.top.bottom.right.equalTo(contentView)
        }
        
        arrowImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 7, height: 12))
            make.centerY.equalTo(contentView)
            make.right.equalTo(-15)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var infoLabel: UILabel = {
        let label = UILabel()
        label.text = "查看聊天记录"
        return label
    }()
    
    lazy var arrowImageView: UIImageView = {
        let imgView = UIImageView()
        let image = UIImage(named: "right_arrow", aclass: self.classForCoder)
        imgView.image = image
//        imgView.contentMode = .right
        return imgView
    }()
}

// MARK: 群公告
class RKChatBoardCell: RKChatSettingCell {
    override func reloadCell(_ model: RKIMGroup) {
        noticeLabel.text = model.groupConfig
    }
    override class func heightForCell(_ groupInfo: RKIMGroup) -> CGFloat {
        return 54
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubViews([infoLabel, noticeLabel])
        initlayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initlayout() {
        infoLabel.snp.makeConstraints { make in
            make.left.equalTo(15)
            make.top.equalTo(10)
            make.height.equalTo(18)
            make.right.equalTo(contentView)
        }
        noticeLabel.snp.makeConstraints { make in
            make.top.equalTo(infoLabel.snp_bottom).offset(10)
            make.width.equalTo(contentView).offset(-30)
            make.bottom.equalTo(contentView).offset(-10)
            make.centerX.equalTo(contentView)
        }
    }
    
    lazy var infoLabel: UILabel = {
        let label = UILabel()
        label.text = "群简介"
        return label
    }()
    
    lazy var noticeLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()
}


extension RKChatSettingMemberCell: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.register(RKChatSettingCollectionCell.classForCoder(), forCellWithReuseIdentifier: "RKChatSettingCollectionCell")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RKChatSettingCollectionCell", for: indexPath)
        if let cell = cell as? RKChatSettingCollectionCell {
            cell.imageView.backgroundColor = .init(hex: 0xF8F9FB)
            if indexPath.row == groupInfo.userList.count - 1 {
                let image = UIImage(named: "invite_member", aclass: self.classForCoder)
                cell.imageView.contentMode = .center
                cell.imageView.image = image
            } else {
                let url = groupInfo.userList[indexPath.row].headPortrait
                cell.imageView.contentMode = .scaleAspectFit
                let image = UIImage(named: "default_avatar", aclass: self.classForCoder)
                cell.imageView.kf.setImage(with: URL(string: url), placeholder: image)
            }
        }
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
       return groupInfo.userList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == groupInfo.userList.count - 1 {
            #warning("TODO 邀请用户")
        }
    }
}
