//
//  RKFileTool.swift
//  RKIM
//
//  Created by chzy on 2022/2/21.
//

import Foundation
import RKIUtils

class RKFileTool: NSObject {
    static let shareManager = RKFileTool()
    
    func openfile(_ url: String, compeletBlock: @escaping(String)-> Void) {
        if let urlab = url.split(separator: "/").last {
            let path = RKFileUtil.fileDir() + "/\(urlab)"
            if FileManager.default.fileExists(atPath: path) {
                DispatchQueue.main.async {
                    compeletBlock(path)
                }
            } else {
                downloadfile(url: url) { data in
                    (data as NSData).write(toFile: path, atomically: true)
                    DispatchQueue.main.async {
                        compeletBlock(path)
                    }
                }
            }
           
        }
    }
    
    func downloadfile(url:String, compeletBlock: @escaping (Data)-> Void) {
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
            queue.name = "Download file queue"
            queue.maxConcurrentOperationCount = 1
            return queue
    }()
}
