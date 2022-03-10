//
//  RKImageVideoMessageVC.swift
//  RKIM
//
//  Created by chzy on 2022/2/18.
//  图片视频消息搜索页面

import Foundation
import UIKit
import RKIMCore
import Kingfisher
import QuickLook
import RKIUtils

class RKImageVideoMessageVC: UIViewController {
    var groupID: String?
    var messageType: MessageContentType = .Text
    var messagList: [RKIMMessage] = [RKIMMessage]()
    var index = 1
    let pageSize = 30
    var nowFilePath = ""
   
    func loadData(_ compelet:@escaping ([RKIMMessage]?) ->Void) {
        var sendTimeLongStart: String? = nil
        var sendTimeLongEnd: String? = nil
        if let pickerStartDate = pickerStartDate {
            sendTimeLongStart = "\(Int(pickerStartDate.timeIntervalSince1970 * 1000))"
        }
        if let pickerEndDate = pickerEndDate {
            sendTimeLongEnd = "\(Int(pickerEndDate.timeIntervalSince1970 * 1000))"
        }
                
        guard let groupID = groupID else { return }
        RKIMManager.share.searchHistoryMessage(recieverGroup: groupID, messageInfo: nil, messageType: Int(messageType.rawValue)!, pageIndex: index, pageSize: pageSize, sendTimeLongStart: sendTimeLongStart, sendTimeLongEnd: sendTimeLongEnd) { isSuccess, errorMsg, messags in
            self.refreshControl.endRefreshing()
            if let messags = messags {
                self.messagList.append(contentsOf: messags)
                self.collectionView.reloadData()
                self.index += 1
                compelet(messags)
            } else {
                compelet(messags)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubViews([startTimeLabel,
                          endTimeLabel,
                          collectionView])
        startTimeLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(40)
            make.top.equalTo(10)
        }
        
        endTimeLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(40)
            make.top.equalTo(startTimeLabel.snp_bottom).offset(5)
        }
        
        startTimeLabel.text = "请选择开始时间"
        startTimeLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showStartTimePicker)))
       
        endTimeLabel.text = "请选择结束时间"
        endTimeLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showEndTimePicker)))
        
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets(top: 100, left: 0, bottom: 0, right: 0))
        }
        
        if #available(iOS 10.0, *) {
            collectionView.refreshControl = refreshControl
        } else {
            // Fallback on earlier versions
        }

        loadData{_ in }
        
        let rightItem = UIBarButtonItem(title: "搜索", style: .done, target: self, action: #selector(resetSearch))
        navigationItem.rightBarButtonItem = rightItem
    }
    
    @objc private func resetSearch() {
        index = 1
        self.messagList.removeAll()
        pullDown()
    }
    
    @objc func pullDown() {
        
        loadData { _ in
            self.refreshControl.endRefreshing()
        }
    }
    
    var iSshowDatePickerStartTime = false
    var pickerStartDate: Date? {
        didSet {
            guard let date = pickerStartDate else { return }
            startTimeLabel.text = "开始时间:" + date.toString(format: .custom("yyyy-MM-dd HH:mm"))
      }
    }
    
    var pickerEndDate: Date? {
        didSet {
            guard let date = pickerEndDate else { return }
            endTimeLabel.text = "开始时间:" + date.toString(format: .custom("yyyy-MM-dd HH:mm"))
        }
        
    }
    
    @objc private func showStartTimePicker() {
        pickerView.show(view)
        iSshowDatePickerStartTime = true
    }
    
    @objc private func showEndTimePicker() {
        pickerView.show(view)
        iSshowDatePickerStartTime = false
    }
    
    lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 90, height: 120)
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .white
        return collectionView
    }()
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .brown
        refreshControl.attributedTitle = NSAttributedString(string: "下垃加载更多")
        refreshControl.addTarget(self, action: #selector(pullDown), for: .valueChanged)
        return refreshControl
    }()
    
    
    lazy var startTimeLabel: UILabel = {
        let label = UILabel()
        label.isUserInteractionEnabled = true
        return label
    }()
    
    lazy var endTimeLabel: UILabel = {
        let label = UILabel()
        label.isUserInteractionEnabled = true
        return label
    }()
    
    lazy var pickerView: DatePickerView = {
        let pickerView = DatePickerView(view)
        pickerView.delegate = self
        return pickerView
    }()
}

extension RKImageVideoMessageVC: DatePickerDelegate {
    
    func pickerSure(date: Date) {
        if iSshowDatePickerStartTime {
            pickerStartDate = date
        } else {
            pickerEndDate = date
        }
    }
    
}

extension RKImageVideoMessageVC: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messagList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.register(RKImageVideoMessageCell.classForCoder(), forCellWithReuseIdentifier: "RKImageVideoMessageCell")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RKImageVideoMessageCell", for: indexPath)
        if let cell = cell as? RKImageVideoMessageCell {
            cell.fillData(messagList[indexPath.row])
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let message = messagList[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RKImageVideoMessageCell", for: indexPath)
        if let cell = cell as? RKImageVideoMessageCell {
            switch message.messageType {
            case .Video, .Image:
                IMPhotoBrowser.showBrowser(messagList, message, self, cell.imageView)
            case .File:
                guard let fileUrl = message.messageDetailModel?.fileUrl else { return }
                RKFileTool.shareManager.openfile(fileUrl, compeletBlock: { path in
                    self.nowFilePath = path
                    let previewController = QLPreviewController()
                    previewController.delegate = self;
                    previewController.dataSource = self;
                    self.present(previewController, animated: true, completion: nil)
                })
            default: break
            }
        }
    }
    
}


class RKImageVideoMessageCell: UICollectionViewCell {
    
    private var message: RKIMMessage? {
        didSet {
            if let message = message {
                if message.messageType == .Video {
                    playView.isHidden = false
                } else if message.messageType == .Image {
                    playView.isHidden = true
                } else if message.messageType == .File {
                    fileLabel.isHidden = false
                }
            }
        }
    }
    
    override
    init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubViews([fileLabel, imageView, playView, timeLabel])
        imageView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(timeLabel.snp_top)
        }
        playView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 20, height: 20))
            make.center.equalTo(imageView)
        }
        fileLabel.snp.makeConstraints { make in
            make.edges.equalTo(imageView)
        }
        timeLabel.snp.makeConstraints { make in
            make.bottom.width.left.equalTo(self)
            make.height.equalTo(30)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var imageView: UIImageView = {
        let imageview = UIImageView()
        return imageview
    }()
    
    lazy var playView: UIImageView = {
        let imageview = UIImageView()
        imageview.isHidden = true
        imageview.image = UIImage(named: "play", aclass: self.classForCoder)
        return imageview
    }()
    
    lazy var fileLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .brown
        label.textAlignment = .center
        label.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        return label
    }()
    
    lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .red
        label.textAlignment = .center
        label.backgroundColor = .white
        label.font = .systemFont(ofSize: 8)
        return label
    }()
    public func fillData(_ message: RKIMMessage) {
        
        self.message = message
        switch message.messageType {
        case .Image, .Video:
            guard let thumbUrl = message.messageDetailModel?.thumbUrl else { return }
            imageView.kf.setImage(with: URL(string: thumbUrl))
        case .File:
            guard let txtStr = message.messageDetailModel?.fileName else {
                return
            }
            let fileDes =  "【文件消息】" + txtStr
            let str = message.messageType != .File ? "未知消息" : fileDes
            fileLabel.text = str
        default: break
        }
        
         let sendTimeLong = Int64(message.sendTimeLong / 1000)
//        dateFormatString
        timeLabel.text = String.dateFormatString(timeStamp: sendTimeLong)//, formatStr: "MM-dd HH:mm:ss")
//        RKChatToolkit.formatCallDate(date: Date(timeIntervalSince1970: message.sendTimeLong/1000) as Date)

    }
}


extension RKImageVideoMessageVC: QLPreviewControllerDelegate, QLPreviewControllerDataSource {
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        let qlItem = RKQLFileItem()
        qlItem.previewItemURL = URL(fileURLWithPath: self.nowFilePath)
        return qlItem
        //self.nowFileMessage
    }
    
}
