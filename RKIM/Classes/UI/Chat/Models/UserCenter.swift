//
//  UserCenter.swift
//  AFNetworking
//
//  Created by chzy on 2022/3/7.
//

import Foundation
import RKIMCore

public class DemoUserCenter {
    public static var userInfo = RKIMUser()
}

extension String {
    /// id 对应的用户名
    func userName() ->String? {
        for user in KContacts {
            if user.userId == self {
                return user.realName.isEmpty ? user.username : user.realName
            }
        }
        return nil
    }
    /// id 对应的用户头像
    func userAvator() ->String? {
        for user in KContacts {
            if user.userId == self {
                return user.headPortrait
            }
        }
        return nil
    }
}
