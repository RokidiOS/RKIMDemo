//
//  MoyaResult.swift
//  RKIM
//
//  Created by chzy on 2021/11/1.
//

import Foundation
import Moya
import Result

public class IMResponse {
    var code: Int = 200
    var success: Bool = false
    var message: String = ""
    var data: Any?
}

/// 接口回调
extension Result where Success == Moya.Response, Failure == Moya.MoyaError {
    func commen(callback: (Bool, Any, String, Int) -> Void) {
        var success = false
        let resposeData: IMResponse = IMResponse()
        var errorMsg: String = ""
        var errorCode: Int = 0
        switch self {
        case let .success(response):
            do {
                guard let json = try response.filterSuccessfulStatusAndRedirectCodes().mapJSON() as? [String: Any] else {
                    break
                }
                resposeData.code = (json["code"] as? Int) ?? -1
                resposeData.success = (json["success"] as? Bool) ?? false
                resposeData.message = (json["message"] as? String) ?? ""
                resposeData.data = json["data"]
                errorCode = resposeData.code
                if resposeData.code == 200 {
                    success = true
                }
            }
            catch _ {
                success = false
                errorMsg = "未知错误，请稍后重试 ..."
                break
            }
            break
        case let .failure(error):
            errorCode = error.errorCode
            errorMsg = error.errorDescription ?? "网络错误"
        }
        callback(success, resposeData.data, errorMsg, errorCode)
    }
}
