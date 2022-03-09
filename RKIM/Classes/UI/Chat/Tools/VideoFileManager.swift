//
//  VideoFileManager.swift
//  VideoDownloader
//
//  Created by chzy on 2022/2/13.
//  视频文件保存以及获取

import Foundation
import AVFoundation

class VideoFileManager: NSObject {
    
    static let shared = VideoFileManager()
    let infoplist = "info_"
    func creatFileDir(_ url: URL) {
        let videoDir = url.videoDir()
        var isDir:ObjCBool = true
        let isCreated = FileManager.default.fileExists(atPath: videoDir, isDirectory: &isDir)
        if !isCreated {
           try? FileManager.default.createDirectory(atPath: videoDir, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    func saveFile(_ url: URL, data: Data) {
        let videoDir = url.videoDir() + "/"
        creatFileDir(url)
        do {
            let _ = try FileManager.default.contentsOfDirectory(atPath: videoDir)

        } catch {
            
        }
        let videoPath = videoDir + url.lastPathComponent
        let isSuc = FileManager.default.createFile(atPath: videoPath, contents: data, attributes: nil)
        if isSuc {
            print("写入成功" + videoPath)
        }
    }
    
    func existInfo(_ url: URL) -> VideoHttpHeaderInfo? {
        let videoDir = url.videoDir() + "/"
        let videoInfoPath = videoDir + infoplist
        if FileManager.default.fileExists(atPath: videoInfoPath) {
            let data = try! Data(contentsOf: URL(fileURLWithPath: videoInfoPath))
            let dict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
            if let dict = dict as? [String: Any] {
                return VideoHttpHeaderInfo(dict)
            }
        }
        return nil
    }
    
    func saveInfo(_ url: URL, data: Data) {
        let videoDir = url.videoDir() + "/"
        creatFileDir(url)
        do {
            let _ = try FileManager.default.contentsOfDirectory(atPath: videoDir)

        } catch {
            
        }
        let videoInfoPath = videoDir + infoplist
        let isSuc = FileManager.default.createFile(atPath: videoInfoPath, contents: data, attributes: nil)
        if isSuc {
            print("写入成功info数据" + videoInfoPath)
        }
    }
    
    func asGetVideofile(_ url: URL) -> (Data?, URL){
        
        let videoDir = url.videoDir() + "/" + url.lastPathComponent
        creatFileDir(url)
        let url = URL(fileURLWithPath: videoDir)
        do {
            if FileManager.default.fileExists(atPath: videoDir) {
                let url = URL(fileURLWithPath: videoDir)
                return (try Data(contentsOf: url), url)
            }
        } catch {
            return (nil, url)
        }
        return (nil, url)
    }
    
    
}
