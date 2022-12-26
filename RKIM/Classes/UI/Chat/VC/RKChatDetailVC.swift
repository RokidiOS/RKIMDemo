//
//  RKChatDetailVC.swift
//  RKIM
//
//  Created by chzy on 2021/11/3.
//  聊天详情

import Foundation
import RKIUtils
import RKIBaseView
import Then
import UIKit
import Kingfisher
import IQKeyboardManager
import RKIHandyJSON
import RKILogger
//import RKImagePicker
import TZImagePickerController
import MobileCoreServices
import RKIMCore
import WCDBSwift
import QuickLook

public class RKChatDetailVC: UIViewController,
                             UITableViewDelegate, UITableViewDataSource, QLPreviewControllerDelegate, QLPreviewControllerDataSource {
    
    // MARK: lifeCycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        firstMessageTms = Int(nowTime())
        //有历史消息时，自动定位到当前历史消息
        if let _ = locationMessage {
            locationLoadAction()
        } else { //正常加载消息
            chatTableView.isHidden = true
            loadData { _ in
                self.chatTableView.isHidden = false
                self.chatTableView.reloadData()
                self.scrollToBottom(false)
            }
        }
        RKIMManager.share.addDelegate(newDelegate: self)

        unreadAction()
        
    }
    
    deinit {
        print("dealloc detail vc")
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        IQKeyboardManager.shared().isEnableAutoToolbar = false
        //防止调用sdk的外部隐藏了navigation
        navigationController?.setNavigationBarHidden(false, animated: animated)
        bottomFunctionView.addKeyboardNotif()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        IQKeyboardManager.shared().isEnableAutoToolbar = true
        view.endEditing(false)
        bottomFunctionView.removeKeyboardNotif()
        RKRecordTool.shareManager.stopPlay()
    }
    
    // MARK: - 从会议返回
    @objc func exitMeeting() {
        //查询会议状态
//        queryMeeting() 走网络请求
        
    }
    
    var bottomGap = 100.0
    // MARK: loadData
    func pullDown() {
        bottomGap = chatTableView.contentSize.height - chatTableView.bounds.size.height
        self.refreshStatus = .refreshing
        loadData { requestCount in
            self.chatTableView.reloadData()
            // 是否显示能下拉菊花控件
            if requestCount == 0{
                self.chatTableView.tableHeaderView = nil
                self.refreshStatus = .noMore
            } else {
                self.chatTableView.tableHeaderView = self.refreshHeaderView
                self.refreshStatus = .Idle
            }
            
            // 是否滚动到底部
            if self.messageList.count > self.pageSize {
                guard let firstMessage = self.firstMessage else { return }
                guard let idx = self.messageList.firstIndex(where: { $0.id == firstMessage.id }) else { return }
                let indexPath = IndexPath(row: idx, section: 0)
                self.chatTableView.scrollToRow(at:indexPath, at: UITableView.ScrollPosition.top, animated: false)
                var offsetY = self.chatTableView.contentOffset.y
                offsetY -= self.refreshHeaderHeight
                self.chatTableView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: false)
            } else {
                self.scrollToBottom()
            }
            
        }

    }
    var localPageIndex = 1
    var pageIndex = 1
    var firstMessage: RKIMMessage?
    func loadData(_ compelet: @escaping (NSInteger) ->Void){
        
        RKIMManager.share.historyMessage(reciever: nil, receiveGroup: groupId, pageSize: "\(pageSize)", pageIndex: "\(pageIndex)", sendTimeLongEnd: String(firstMessageTms)) { isSuccess, errorMessage, messageList in
            if isSuccess {
                self.pageIndex += 1
                if let list = messageList {
                    for localmsg in self.messageList {
                        if let _ = list.first(where: { perMsg in
                            perMsg.id == localmsg.id

                        }) {

                            DBHelper.asyDeletMsg(localmsg.id) { isSuccess in
                                self.messageList.removeAll { msg in
                                    msg.id == localmsg.id
                                }
                            }
                        }
                    }
                    if self.firstMessage == nil {
                        self.firstMessage = self.messageList.first
                    }
                    self.messageList(addList: list)
                    RKIMDBManager.dbAddObjects(self.messageList)
                    compelet(list.count)
                    guard let message = self.messageList.first else {
                        return
                    }
                    self.firstMessageTms = Int(message.sendTimeLong)
                }
            } else {
                
            }
        }
        
        let nowGroupCondition = Expression(with: Column(named: "receiveGroup")) == groupId ?? ""
        let tmsConCondition = Expression(with: Column(named: "sendTimeLong")) < firstMessageTms
        RKIMDBManager.queryObjects(RKIMMessage.self
                                   , where: nowGroupCondition && tmsConCondition
                                   , limit: pageSize
                                   , offset: (localPageIndex - 1) * pageSize
                                   , orderBy: [ RKIMMessage.Properties.sendTimeLong.asOrder(by: .descending)]
        ) { localMessages in
                if localMessages.isEmpty {
                    self.firstMessage = nil
                    return
                }
                self.localPageIndex += 1
                self.firstMessage = self.messageList.first
                self.messageList(addList: localMessages)
                compelet(localMessages.count)
        }
        
        
    }
    
    /// 获取缺失的消息  掉线后重连 执行
    func loadMissingMessage() {
        if messageList.isEmpty { return }
        let ms = self.messageList[self.messageList.count - 1]
        guard let groupId = groupId else { return }
        RKIMManager.share.missedMessage(recieverGroup: groupId, messageStart: ms.sendTimeLong) { _, _, missedMessages in
            guard let missedMessages = missedMessages else { return  }
            self.messageList(addList: missedMessages)
            RKIMDBManager.dbAddObjects(self.messageList)
            self.chatTableView.reloadData()
        }
            
    }
    
    func locationLoadAction() {
        let nowGroupCondition = Expression(with: Column(named: "receiveGroup")) == groupId ?? ""
  
        RKIMDBManager.queryObjects(RKIMMessage.self,
                                   where: nowGroupCondition,
                                   orderBy: [ RKIMMessage.Properties.sendTimeLong.asOrder(by: .ascending)])
        { localMessages in
            self.messageList = localMessages
            self.chatTableView.reloadData()
            self.location(self.locationMessage)
        }
                                   
    }
    
    ///定位到当前cell
    func location(_ loactionMessage: RKIMMessage?) {
        guard let locationMessage = locationMessage else { return }
        var index: Int?
        if let message = messageList.first(where: {$0.sendTimeLong == locationMessage.sendTimeLong}) {
            index = messageList.firstIndex(of: message)
        }
        guard let index = index else { return }
        let indexPath = IndexPath(row: index, section: 0)
        let _ = chatTableView.cellForRow(at: indexPath)
        self.chatTableView.cellForRow(at: indexPath)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.chatTableView.scrollToRow(at: indexPath, at: .top, animated: false)
        }

    }
    
    /// 设置 已读回调
    /// 进入聊天详情 设置当前群聊未读数为0  收到消息时；
    /// 当前消息群群groupid与收到消息id一致时；
    func unreadAction() {
        
        if let groupID = groupId {
            RKIMManager.share.updateMessageRecordTime(groupId: groupID) { isSuccess, errorMessage, result in
                if isSuccess {
                    
                }
            }
        }
    }
    
    func messageList(addList: [RKIMMessage]) {
        messageList.append(contentsOf: addList)
        messageList = messageList.filterDuplicates({$0.sendTimeLong}).filterDuplicates({$0.id}).sorted { s1, s2 in
            s1.sendTimeLong < s2.sendTimeLong
        }
    }
    

    // MARK: UI config
    func setupView() {
        view.addSubViews([chatTableView, bottomFunctionView])
        layoutUI()
        navigationConfig()
    }
    
    func layoutUI() {
        chatTableView.snp.makeConstraints { make in
            make.top.left.right.equalTo(view)
            make.bottom.equalTo(bottomFunctionView.snp_top).priorityHigh()
        }
        bottomFunctionView.snp.makeConstraints { make in
            make.left.right.equalTo(view)
            make.bottom.equalTo(view).offset(-UI.SafeBottomHeight)
        }
    }
    
    func navigationConfig() {
        var image = UIImage(named: "chat_more", aclass: self.classForCoder)
        image = image?.withRenderingMode(.alwaysOriginal)
        let rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(rightBarButtonItemAction))
        self.navigationItem.rightBarButtonItem = rightBarButtonItem
    }
    
    // MARK: properties
    //下拉刷新状态
    enum RefreshStatus {
        case Idle
        case refreshing
        case noMore
    }
    //刷新头
    private lazy var refreshHeaderView = UIView().then { headerView in
        headerView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: refreshHeaderHeight)
        let indicatorView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
        headerView.addSubview(indicatorView)
        indicatorView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        indicatorView.startAnimating()
    }
    
    
    private let refreshHeaderHeight: CGFloat = 40//刷新头的高度
    private var refreshStatus: RefreshStatus = .Idle//记录刷新状态
   
    var locationMessage: RKIMMessage? ///< 定位消息
    
    lazy var chatTableView = RKBaseTableView().then { tableView in
        tableView.backgroundColor = .init(hex: 0xF8F9FB)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 60
    }
    
    lazy var bottomFunctionView = RKChatDetailFunctionView().then { funcView in
        
        funcView.delegate = self
    }
    
    lazy var tpControl: UIView = {
        let tpcontrol = UIView()
        tpcontrol.alpha = 0
        tpcontrol.backgroundColor = .clear
        chatTableView.addSubview(tpcontrol)
        tpcontrol.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
        tpcontrol.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(hiddenInputView)))
        return tpcontrol
    }()
    
    var groupId: String? /// 群组id
    /// 是否是单聊
    var isSingleChat: Bool = true
    var groupInfo: RKIMGroup?//群组信息
    var groupMemberCount = 2 /// 群组人数
    private var firstMessageTms = 0 ///第一条的时间戳
    private var pageSize = 30   /// 当前加载的size
    var messageList: [RKIMMessage] = []
    ///当前选中的文件message
    var nowFilePath: String = ""
    
    var refreshBlock: ((Bool) ->Void)?
    // MARK: obj action
    
    @objc func hiddenInputView() {
        view.endEditing(true)
        bottomFunctionView.hideFunction()
    }
    
    func appdenMessageScrollToBottom(_ message: RKIMMessage) {
        DispatchQueue.main.async {
            self.messageList.append(message)
            RKIMDBManager.dbAddObjects([message])
            self.chatTableView.reloadData()
            self.scrollToBottom()
        }
    }
    
    @objc func rightBarButtonItemAction() {

        guard let groupID = groupId else { return }
 
        let alertVC = UIAlertController(title: "群内功能", message: nil, preferredStyle: .actionSheet)
        
        let infoActio = UIAlertAction(title: "群内信息展示", style: .default) {[weak self] _ in
            self?.showGroupInfo()
        }
        
        let historyAction = UIAlertAction(title: "群历史消息", style: .default) {[weak self] _ in
            self?.groupHistoryMessage()
        }
        
        let inviteAction = UIAlertAction(title: "邀请群成员", style: .default){[weak self] _ in
            self?.inviteAction()
        }
        
        let changeGroupNameAction = UIAlertAction(title: "修改群名称", style: .default) {[weak self] _ in
            self?.showChangeGroupTitleAlert()
        }
        
        let reOwnerAction = UIAlertAction(title: "转让群主", style: .default) {[weak self] _ in
            self?.reOwnerAction()
        }
        
        let dismissAction = UIAlertAction(title: "解散群组", style: .default) {[weak self] _ in
            self?.dismissGroup()
        }
        
        let removeAction = UIAlertAction(title: "移除群成员", style: .default) {[weak self] _ in
            self?.removeMemberAction()
        }
        
        let exitAction = UIAlertAction(title: "退群", style: .default) {[weak self] _ in
            self?.exitAction()
        }
        
        let memberAction = UIAlertAction(title: "群成员列表", style: .default) {[weak self] _ in
            self?.groupMemberList()
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .destructive) { _ in
            alertVC.dismiss(animated: true, completion: nil)
        }
        
        if let groupInfo = groupID.groupInfo {
            var array = [infoActio, historyAction,changeGroupNameAction, inviteAction, memberAction]
            if groupInfo.groupType == .singleGroup {
                array = [historyAction]
            } else if groupInfo.ownerId == kUserId {
                array.append(reOwnerAction)
                array.append(removeAction)
                array.append(dismissAction)
            } else {
                array.append(exitAction)
            }

            array.append(cancelAction)
            for action in array {
                alertVC.addAction(action)
            }

            self.present(alertVC, animated: true, completion: nil)

        }
    }
    
    func getGroupInfo() {
       
    }
    // MARK: 发信息接口
    func sendMessage(_ message: RKIMMessage) {
        guard let groupID = groupId else { return }
        
        message.unread = groupMemberCount - 1
        RKIMManager.share.sendMessage(message) { percent in
            message.progess = percent
            self.chatTableView.reloadData()
        } compelet: { isSuccess, errorMessage, result in
            message.status = .fail
            if isSuccess {
                message.status = .success
                
                DBHelper.asyMessage(message.id, groupID) { dbMessage in
                    let listMessage = self.messageList.first { lmessage in
                        lmessage.id == message.id
                    }
                    //刷新内存中消息id 未读数默认为当前群成员数-1
                    if let messageID = result as? String {
                        message.id = messageID
                        listMessage?.id = messageID
                        listMessage?.unread = self.groupMemberCount - 1
                    }
                    //刷新db中 消息id
                    RKIMDBManager.dbAddObjects([message])
                }
                
            }
            self.chatTableView.reloadData()
        }
    }
    
    lazy var voiceTipView: RecordTipView = {
        let voiceTipView = RecordTipView(frame: .zero)
        view.addSubview(voiceTipView)
        voiceTipView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(100)
            make.bottom.equalTo(-100)
        }
        return voiceTipView
    }()

    @objc public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageList.count
    }
    
    @objc public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    @objc public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.register(RKChatTxtCell.classForCoder(), forCellReuseIdentifier: RKChatTxtCell.cellIdeString)
        tableView.register(RKChatImageCell.classForCoder(), forCellReuseIdentifier: RKChatImageCell.cellIdeString)
        tableView.register(RKChatSystemCell.classForCoder(), forCellReuseIdentifier: RKChatSystemCell.cellIdeString)
        tableView.register(RKChatVideoCell.classForCoder(), forCellReuseIdentifier: RKChatVideoCell.cellIdeString)
        tableView.register(RKChatVoiceCell.classForCoder(), forCellReuseIdentifier: RKChatVoiceCell.cellIdeString)
        tableView.register(RKChatFileCell.classForCoder(), forCellReuseIdentifier: RKChatFileCell.cellIdeString)
        let message = messageList[indexPath.row]
        let isShowTime = checkMessageShouldShowTime(message: message)
        var tpcell: RKChatDetailCell!
        switch message.messageType {
        case .system:
            let systemCell = tableView.dequeueReusableCell(withIdentifier: RKChatSystemCell.cellIdeString, for: indexPath)
            if let cell = systemCell as? RKChatSystemCell {
                cell.setModel(message)
            }
            return systemCell
        case .Text:
            let textCell = tableView.dequeueReusableCell(withIdentifier: RKChatTxtCell.cellIdeString, for: indexPath)
            if let cell = textCell as? RKChatTxtCell {
                cell.setModel(message, isShowTime)
                tpcell = cell
            }
            
        case .Image:
            let imgeCell = tableView.dequeueReusableCell(withIdentifier: RKChatImageCell.cellIdeString, for: indexPath)
            if let cell = imgeCell as? RKChatImageCell {
                cell.setModel(message, isShowTime)
                tpcell = cell
            }
            
        case .Voice:
            let voiceCell = tableView.dequeueReusableCell(withIdentifier: RKChatVoiceCell.cellIdeString, for: indexPath)
            if let cell = voiceCell as? RKChatVoiceCell {
                cell.setModel(message, isShowTime)
                tpcell = cell
            }
            
        case .Video:
            let videoCell = tableView.dequeueReusableCell(withIdentifier: RKChatVideoCell.cellIdeString, for: indexPath)
            if let cell = videoCell as? RKChatVideoCell {
                cell.setModel(message, isShowTime)
                tpcell = cell
            }
        case .File:
            let fileCell = tableView.dequeueReusableCell(withIdentifier: RKChatFileCell.cellIdeString, for: indexPath)
            if let cell = fileCell as? RKChatFileCell {
                cell.setModel(message, isShowTime)
                tpcell = cell
            }
        case .Unknown: break
            
        case .none: break
        default: break
        }
        if tpcell != nil {
            tpcell.delegate = self
        }
        guard let tpcell = tpcell else {
        // 未知消息处理
            let textCell = tableView.dequeueReusableCell(withIdentifier: RKChatTxtCell.cellIdeString, for: indexPath)
            if let cell = textCell as? RKChatTxtCell {
                cell.setModel(message, isShowTime)
                tpcell = cell
            }
            return tpcell
        }
        return tpcell
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        bottomFunctionView.hideFunction()
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            scrollViewDidEndDecelerating(scrollView)
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let contentOffsetY = scrollView.contentOffset.y
        if contentOffsetY < refreshHeaderHeight && self.refreshStatus == .Idle{
            pullDown()
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
}



// MARK: - UIImagePickerControllerDelegate
extension RKChatDetailVC: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let medieType = info[UIImagePickerController.InfoKey.mediaType] as! String
        if medieType == String(kUTTypeImage) {
            //获取原图
            guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
                return
            }
            //保存到相册
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            //发送图片
            //            sendImage(oringinImage: image)
            uploadImage(image, nil)
        } else {
            //原视频URL
            guard let mediaUrl = info[UIImagePickerController.InfoKey.mediaURL] as? URL else {
                return
            }
            //保存视频到相册
            UISaveVideoAtPathToSavedPhotosAlbum(mediaUrl.path, nil, nil, nil)
      
            let videoData = try? Data(contentsOf: mediaUrl)
            guard let videoData = videoData else { return }
            uploadVideo(videoData, nil)
            
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        
    }
}

extension RKChatDetailVC: RKChatDetailFunctionDelegate {
    
    func sendTxtMessage(_ messageString: String) {
       let textMessage = RKIMManager.share.createTextMessage(reciever: nil, receiveGroup: groupId, text: messageString)
        guard let textMessage = textMessage else { return }
        appdenMessageScrollToBottom(textMessage)
        sendMessage(textMessage)
    }
    
    func sendVoiceMessage() {
        guard let voicePath = RKRecordTool.shareManager.accPath else {
            return
        }
        let voiceURL = URL(fileURLWithPath: voicePath)
        let voiceDuration = RKRecordTool.shareManager.lastDuration
        do {
            let data = try Data(contentsOf: voiceURL)
            uploadVoice(data, voiceDuration, nil)
        } catch {
            print("音频文件丢失")
        }
    }
    
    func goImage() {
        let vc = TZImagePickerController(maxImagesCount: 9, delegate: nil)!
        vc.allowTakeVideo = false
        vc.allowTakePicture = false
        vc.allowPickingMultipleVideo = true

        vc.didFinishPickingPhotosHandle = { (photos: [UIImage]?,assets: [Any]?, isSelectOriginalPhoto: Bool) in
            guard let assets = assets as? [PHAsset] else { return }
            for asset in assets {
                let type = TZImageManager.default().getAssetType(asset)
                if type == TZAssetModelMediaTypePhoto {
                    TZImageManager.default().getPhotoWith(asset) { img, _, isDegraded in
                        guard let img = img else { return }
                        //发送原图，而非缩略图
                        if !isDegraded {
                            self.uploadImage(img, nil)
                        }
                    }
                } else if type == TZAssetModelMediaTypeVideo {
                    TZImageManager.default().getVideoOutputPath(with: asset, presetName: AVAssetExportPresetHighestQuality) { path in
                        if let path = path {
                            let videoData = try? Data(contentsOf: URL(fileURLWithPath: path))
                            guard let videoData = videoData else { return }
                            self.uploadVideo(videoData, nil)
                        }
                    } failure: { errorString, _ in
                        RKLog("\(String(describing: errorString))",.error)
                    }

                }
            }
        }
        self.present(vc, animated: true, completion: nil)
    }
    
    func goCamera() {
        RKAuthorizationManager.authorization(.camera) { granted in
            if granted {
                let imagePicker = UIImagePickerController()
                imagePicker.sourceType = .camera
                imagePicker.delegate = self
                imagePicker.allowsEditing = false
                //设置闪光灯(On:开、Off:关、Auto:自动)
                //            imagePicker.cameraFlashMode = UIImagePickerController.CameraFlashMode.on
                imagePicker.mediaTypes = [kUTTypeImage as String,kUTTypeMovie as String]
                imagePicker.videoMaximumDuration = 59
                imagePicker.videoQuality = .typeHigh
                self.present(imagePicker, animated: true, completion: nil)
            } else {
                RKToast.show(withText: "相机权限未打开")
            }
        }
    }
    
    func goMeeting() {
        
    }
    
    
    func scrollToBottom(_ animation:Bool = false) {
        if self.messageList.count  == 0 {
            return
        }
                
        let indexPath = IndexPath(row: self.messageList.count - 1, section: 0)
        self.chatTableView.scrollToRow(at: indexPath, at: .bottom, animated: animation)
    }
    
    func keyboardIsShow(_ isShow: Bool) {
        tpControl.alpha = isShow ? 1 : 0
    }
    // 显示 voice状态
    func showVideoInfo(_ state:VoiceStateType) {
        voiceTipView.isHidden = false
        switch state {
        case .moveUpCancel:
            voiceTipView.recording()
            
        case .MoveOutCancel:
            voiceTipView.slideToCancelRecord()
            
        case .hiden:
                voiceTipView.isHidden = true
        }
        
    }
    
    func showVoideDegree(_ meters: Float) {
        self.voiceTipView.updateMetersValue(meters)
    }
    
    func messageTooShort() {
        self.voiceTipView.isHidden = false
        self.voiceTipView.messageTooShort()
    }
}

// MARK: SocketDelegate
extension RKChatDetailVC: RKIMDelegate {
 
    public func didOpen() {
        self.loadMissingMessage()
    }
    
    public func message(didReceiveSystemMessage message: RKIMMessage) {
        DispatchQueue.global().async {
            if message.messageType == .system {
                self.receiveMessage(message)
            } else if message.messageType == .unread {// 收到未读消息未读数量做减一操作
                guard let tpmessage = self.messageList.first(where: { msg in
                    msg.id == message.id
                }) else { return }
                    if var count = tpmessage.unread {
                        count = max(0, count - 1)
                        RKIMDBManager.dbAddObjects([message])
                        let msg = self.messageList.first { msg in
                            msg.id == message.id
                        }
                        msg?.unread = count
                        DispatchQueue.main.async {
                            self.chatTableView.reloadData()
                        }
                    }
            }
        }
    }
    
    public func message(didReceiveNormalMessage message: RKIMMessage) {
        DispatchQueue.global().async {
            self.receiveMessage(message)
        }
    }
    
    func receiveMessage(_ message: RKIMMessage?) {
        if message?.receiveGroup == self.groupId {
            if message?.messageType != .system {
                self.unreadAction()
            }
            guard  let message = message else { return }
            var hasFound = false
            for perMessage in self.messageList {
                if message.sendTimeLong == perMessage.sendTimeLong {
                    hasFound = true
                    break
                }
                if let perLocalTms = perMessage.messageDetailModel?.localTms , let messageLocalTms = message.messageDetailModel?.localTms  {
                    if perLocalTms == messageLocalTms {
                        perMessage.id = message.id
                        hasFound = true
                        break
                    }
                }
            }
            if !hasFound {
                message.status = .success
//                todo 是否需要滚动到底部
                self.appdenMessageScrollToBottom(message)
            }
            DispatchQueue.main.async {
                self.scrollToBottom()
            }
           
        }
    }

    
}

// MARK: cell Delegate
extension RKChatDetailVC: RKChatDetailCellDelegate {
    func messageCellClick(_ cell: RKChatDetailCell) {
        if cell.isKind(of: RKChatImageCell.classForCoder()) {
            guard let message = cell.message else { return }
            guard let imageCell = cell as? RKChatImageCell else { return }
            IMPhotoBrowser.showBrowser(self.messageList, message, self, imageCell.photoImageView)
        } else if cell.isKind(of: RKChatVideoCell.classForCoder()) {
            guard let message = cell.message else { return }
            guard let videoCell = cell as? RKChatVideoCell else { return }
            IMPhotoBrowser.showBrowser(self.messageList, message, self, videoCell.photoImageView)
        } else if cell.isKind(of: RKChatVoiceCell.classForCoder()) {
            guard let message = cell.message else { return }
            guard let voiceCell = cell as? RKChatVoiceCell else { return }
            let voiceUrl = message.messageDetailModel?.voiceUrl?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            guard let voiceUrl = voiceUrl else { return }
            RKVoiceDownloader.shareManager.downloadVoice(voiceUrl) { path in
               
                RKRecordTool.shareManager.play(path) {
                    animtion in
                    if animtion {
                        voiceCell.voiceAniImgView.startAnimating()
                    } else {
                        RKToast.show(withText: "播放失败")
                    }
                }
                
                RKRecordTool.shareManager.playCallBack { _, vPath in
                    if vPath == path {
                        voiceCell.voiceAniImgView.stopAnimating()
                    }
                }
            }
        } else if cell.isKind(of: RKChatFileCell.classForCoder()) {
//            打开文件
            guard let message = cell.message else { return }
            let fileUrl = message.messageDetailModel?.fileUrl?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            guard let fileUrl = fileUrl else { return }
            RKFileTool.shareManager.openfile(fileUrl, compeletBlock: { path in
                self.nowFilePath = path
                let previewController = QLPreviewController()
                previewController.delegate = self;
                previewController.dataSource = self;
                self.present(previewController, animated: true, completion: nil)
            })
        }
    }
    
    func resendAction(_ cell: RKChatDetailCell) {
        guard let message = cell.message else { return }
        sendMessage(message)
    }
    
    func showUnreadInfo(_ cell: RKChatDetailCell) {
        guard let messageID = cell.message?.id else { return }
        guard let groupID = groupId else { return }
        if messageID.count > 1 {
            let unreadVC = RKMessageUnreadVC.show(groupID, messageID)
            present(unreadVC, animated: true) { }
        } else {
            RKToast.show(withText: "服务端未返回消息id，暂时不支持查看消息未读数", in: view)
        }
       
    }
}


//MARK: - 消息时间
extension RKChatDetailVC {
        
    private func checkMessageShouldShowTime(message:RKIMMessage) ->Bool {

        guard let index = messageList.firstIndex(of: message) else {
            return false
        }
        if index == 0 {
            return true
        }
        let currentTime = message.sendTimeLong
        let previousTime = messageList[index - 1].sendTimeLong
        let diff = currentTime - previousTime
        if diff > 1*60*1000 {
            return true
        }
        return false
    }
}

extension RKChatDetailVC {

    func uploadImage(_ image: UIImage, _ oldMessage: RKIMMessage?) {
        if let oldMessage = oldMessage {
            sendMessage(oldMessage)
        } else {
            let imgeMessage = RKIMManager.share.createImageMessage(reciever: nil, receiveGroup: groupId, image: image)
            guard let imgeMessage = imgeMessage else { return }
            appdenMessageScrollToBottom(imgeMessage)
            sendMessage(imgeMessage)
        }
    }

    func uploadVideo(_ video: Data, _ oldMessage: RKIMMessage?) {
        if let oldMessage = oldMessage {
            sendMessage(oldMessage)
        } else {
            let videoMessage = RKIMManager.share.createVideoMessage(reciever: nil, receiveGroup: groupId, data: video)
            guard let videoMessage = videoMessage else { return }
            appdenMessageScrollToBottom(videoMessage)
            sendMessage(videoMessage)
        }
    }

    func uploadVoice(_ voice: Data, _ duration: Int ,_ oldMessage: RKIMMessage?) {
        if let oldMessage = oldMessage {
            sendMessage(oldMessage)
        } else {
            let voiceMessage = RKIMManager.share.createVoiceMessage(reciever: nil, receiveGroup: groupId, data: voice, duration: duration)
            guard let voiceMessage = voiceMessage else { return }
            appdenMessageScrollToBottom(voiceMessage)
            sendMessage(voiceMessage)
        }
    }
    
    func nowTime() -> Double {
        return Date().timeIntervalSince1970 * 1000
    }
}

extension Array {
    
    // 去重
    func filterDuplicates<E: Equatable>(_ filter: (Element) -> E) -> [Element] {
        var result = [Element]()
        for value in self {
            let key = filter(value)
            if !result.map({filter($0)}).contains(key) {
                result.append(value)
            }
        }
        return result
    }
}

// MARK: 群信息管理
extension RKChatDetailVC {
    
    /// 群信息显示
    func showGroupInfo() {
        guard let groupInfo = groupInfo else { return }
        guard let groupID = groupId else { return }
        let groupInfoVC = RKChatSettingVC()
        groupInfoVC.groupInfo = groupInfo
        groupInfoVC.groupID = groupID
        navigationController?.pushViewController(groupInfoVC, animated: true)
    }
    
    /// 群名称修改弹窗
    func showChangeGroupTitleAlert() {
        guard let groupInfo = groupInfo else { return }
        guard let groupID = groupId else { return }
        let alerControll = UIAlertController(title: "温馨提示", message: "修改群名称", preferredStyle: .alert)
        
        alerControll.addTextField { tf in
            tf.placeholder = "修改群名称"
            tf.text = groupInfo.groupName
        }
        let donelAction = UIAlertAction(title: "确定", style: .default) { _ in
            if let textField = alerControll.textFields?.first {
                guard let groupName = textField.text else {
                    RKToast.show(withText: "群名不能为空", in: self.view)
                    return
                }
                self.changeGroupTitleAction(groupID, groupName)
            }
        }
        let cancelAction = UIAlertAction(title: "取消", style: .destructive) { _ in
            alerControll.dismiss(animated: true, completion: nil)
        }
        alerControll.addAction(cancelAction)
        alerControll.addAction(donelAction)
        present(alerControll, animated: true, completion: nil)
    }
    ///修改群名称
    func changeGroupTitleAction(_ groupID: String, _ groupName: String) {
        RKIMManager.share.updateGroupInfo(groupId: groupID, groupAvatar: "https://img0.baidu.com/it/u=2381979250,1530647734&fm=253&fmt=auto&app=138&f=JPEG?w=708&h=500", groupName: groupName) { isSuccess, errorMessage, result in
            if isSuccess {
                DBHelper.asyGroup(groupID) { model in
                    if let model = model {
                        model.groupName = groupName
                        RKIMDBManager.dbAddObjects([model])
                    }
                }
                RKToast.show(withText: "修改群名成功")
                self.title = groupName
                self.refreshBlock?(true)
            }
        }
    }
    
    
    ///邀请入群
    func inviteAction() {
        guard let groupID = groupId else { return }
        let inviteVC = RKInviteVC()
        inviteVC.groupID = groupID
        self.navigationController?.pushViewController(inviteVC, animated: true)
    }
    
    /// 转让群主
    func reOwnerAction() {
        guard let groupInfo = groupInfo else { return }
        guard let groupID = groupId else { return }
        let groupMemberVC = RKGroupdDetailVC()
        groupMemberVC.dataList = groupInfo.userList.map({ userId -> RKIMUser in
           return userId.userInfo
        })
        groupMemberVC.action = .reOwner
        groupMemberVC.groupID = groupID
        self.navigationController?.pushViewController(groupMemberVC, animated: true)
    }
    
    ///移除群成员
    func removeMemberAction() {
        guard let groupInfo = groupInfo else { return }
        guard let groupID = groupId else { return }
        let groupMemberVC = RKGroupdDetailVC()
        groupMemberVC.dataList = groupInfo.userList.map({ userId -> RKIMUser in
           return userId.userInfo
        })
        groupMemberVC.action = .remove
        groupMemberVC.groupID = groupID
        self.navigationController?.pushViewController(groupMemberVC, animated: true)
    }
    
    ///退群
    func exitAction() {
//        guard let groupInfo = groupInfo else { return }
        guard let groupID = groupId else { return }
        RKIMManager.share.rmoveGroupUsers(groupId: groupID, userList: [kUserId]) { isSuccess, errorMessage, result in
            if isSuccess {
                RKToast.show(withText: "退群成功")
                DBHelper.asyDeletGroup(groupID) { isSucc in
                    self.refreshBlock?(isSucc)

                    self.navigationController?.popViewController(animated: true)
                }
            } else {
                RKToast.show(withText: errorMessage)
            }
        }
    }
    
    ///群成员列表
    func groupMemberList() {
        guard let groupInfo = groupInfo else { return }
        guard let groupID = groupId else { return }
        let groupMemberVC = RKGroupdDetailVC()
        groupMemberVC.dataList = groupInfo.userList.map({ userId -> RKIMUser in
           return userId.userInfo
        })
        groupMemberVC.action = .members
        groupMemberVC.groupID = groupID
        self.navigationController?.pushViewController(groupMemberVC, animated: true)
    }
    
    ///查询群内信息
    func groupHistoryMessage() {
        guard let groupID = groupId else { return }
        let msgHistoryVC = RKMessageHistoryVC()
        msgHistoryVC.groupID = groupID
        self.navigationController?.pushViewController(msgHistoryVC, animated: true)
    }
    
    func dismissGroup() {
        guard let groupID = groupId else { return }
        RKIMManager.share.dissolveGroup(groupId: groupID, compelet: { isSuccess, errorMessage, result in
            if isSuccess {
                RKToast.show(withText: "解散成功", in: self.view)
                self.refreshBlock?(true)
                self.navigationController?.popViewController(animated: true)
            } else {
                RKToast.show(withText: errorMessage, in: self.view)
            }
        })
    }
    
    @objc(numberOfPreviewItemsInPreviewController:) public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        let qlItem = RKQLFileItem()
        qlItem.previewItemURL = URL(fileURLWithPath: self.nowFilePath)
        return qlItem
        //self.nowFileMessage
    }
    
}

class RKQLFileItem: NSObject, QLPreviewItem {
    var previewItemURL: URL?
    override init() {
        super.init()
    }
}
