//
//  RKRecordTool.swift
//  AFNetworking
//
//  Created by chzy on 2022/2/8.
//

import Foundation
import AVFoundation
import RKILogger
import RKIUtils

class RKRecordTool: NSObject {
    var recorder: AVAudioRecorder?
    var player: AVAudioPlayer!
    var recorderSeetingDic: [String: AnyObject]?
    var volumeTimer: Timer?
    var accPath: String?
    var audioArra: [[String: String]] = [[:]]
    var seconds = 0
    let maxDuration = 60 // 最大录音时长
    var lastDuration = 0
    var autoFinishBlock:(() ->Void)? // 自动完成录制
    var lastPlayPath: String?
    var recordUpdate:((Float) ->Void)?
    static let shareManager = RKRecordTool()
    
    override init() {
        super.init()
    }
    
    func startRecord() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSession.Category.playAndRecord)
            try session.setActive(true, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
        }catch {
            RKLog("设置录音session失败")
        }
        
        let docDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let uuid = NSUUID().uuidString
        accPath = docDir + "/\(uuid).acc"
        RKLog(accPath)
        recorderSeetingDic =
                    [AVSampleRateKey : NSNumber(value: Float(8000.0)),//声音采样率
                        AVFormatIDKey : NSNumber(value: Int32(kAudioFormatMPEG4AAC)),//编码格式
                        AVNumberOfChannelsKey : NSNumber(value: 1),//采集音轨
                        AVEncoderAudioQualityKey : NSNumber(value: Int32(AVAudioQuality.medium.rawValue))]//音频质量
        recorder =  try! AVAudioRecorder(url: NSURL(string: accPath!)! as URL,
                                                 settings: recorderSeetingDic!)
        recorder?.isMeteringEnabled = true
        recorder?.prepareToRecord()
        recorder?.record()
       
        volumeTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(countingTimer), userInfo: nil, repeats: true)
        seconds = 0
        let operation = BlockOperation()
        operation.addExecutionBlock(metersUpdate)
        recordQueue.addOperation(operation)
    }
    
    func metersUpdate() {
        guard let recorder = recorder else { return }
        repeat {
            recorder.updateMeters()
            DispatchQueue.main.async {
                let averagePower = recorder.averagePower(forChannel: 0)
                let lowPassResults = pow(10, (0.05 * averagePower)) * 10
                DispatchQueue.main.async {
                    self.recordUpdate?(lowPassResults)
                }
            }
            Thread.sleep(forTimeInterval: 0.05)
        } while (recorder.isRecording && (recordUpdate != nil))
    }
    
    func stopRecord() {
        recorder?.stop()
        recorder = nil
        volumeTimer?.invalidate()
        volumeTimer = nil
        recordUpdate = nil
        recordQueue.cancelAllOperations()
    }
    
    func play(_ audioPath: String, _ animtion: @escaping (Bool) -> Void) {
        do {
            //正在播放的上一个音频和接下来的一致时停止播放
            stopPlay()
            if let lastPlayPath = lastPlayPath {
                if lastPlayPath == audioPath {
                    self.lastPlayPath = nil
                    return
                }
            }
            lastPlayPath = audioPath
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(AVAudioSession.Category.playback)
            try session.setActive(true)
            let url = URL(fileURLWithPath: audioPath)
            if let data = try? Data(contentsOf: url) {
                player = try AVAudioPlayer(data: data)
                player.delegate = self
            }
            
        } catch _ {
            print("播放失败")
        }
        
       if player == nil {
           voiceCallBack?(false, audioPath)
           DispatchQueue.main.async {
               animtion(false)
           }
         
       } else {
           player.prepareToPlay()
           player.play()
           DispatchQueue.main.async {
               animtion(true)
           }
       }

    }
    
    var voiceCallBack: ((Bool, String) -> Void)?
    /// 回调 播放状态
    func playCallBack(_ callBack:@escaping (Bool, String) -> Void) {
        voiceCallBack = callBack
    }
    
    func stopPlay() {
        if player == nil {
            
        } else{
            player.stop()
        }
        if let lastPlayPath = lastPlayPath {
            voiceCallBack?(false, lastPlayPath)
            voiceCallBack = nil
        }
        player = nil
    }
    
    @objc func countingTimer() {
        seconds += 1
        lastDuration = seconds
        if seconds >= maxDuration {
            if let autoFinishBlock = autoFinishBlock {
                autoFinishBlock()
                self.autoFinishBlock = nil
            }
            stopRecord()
        }
    }
    
    lazy var recordQueue: OperationQueue = {
            let queue = OperationQueue()
            queue.name = "recordQueue voice queue"
            queue.maxConcurrentOperationCount = 1
            return queue
    }()
}

extension RKRecordTool: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopPlay()
    }
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        stopPlay()
    }
    func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
        stopPlay()
    }
    func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
        stopPlay()
    }
}

class RKVoiceDownloader: NSObject {
    static let shareManager = RKVoiceDownloader()
    
    func downloadVoice(_ url: String, compeletBlock: @escaping(String)-> Void) {
        if let urlab = url.split(separator: "/").last {
            let path = RKFileUtil.fileDir() + "/\(urlab)"
            if FileManager.default.fileExists(atPath: path) {
                DispatchQueue.main.async {
                    compeletBlock(path)
                }
            } else {
                downloadsong(url: url) { data in
                    (data as NSData).write(toFile: path, atomically: true)
                    DispatchQueue.main.async {
                        compeletBlock(path)
                    }
                }
            }
           
        }
    }
    
    func downloadsong(url:String, compeletBlock: @escaping (Data)-> Void) {
        guard let url = URL(string:url)  else {
            return
        }
        let request = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else {
                return
            }
            compeletBlock(data)
        }
        task.resume()
    }
    
    lazy var downloadQueue: OperationQueue = {
            let queue = OperationQueue()
            queue.name = "Download voice queue"
            queue.maxConcurrentOperationCount = 1
            return queue
    }()
    
}
