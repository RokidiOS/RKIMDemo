//
//  DemoNoticeModel.swift
//  RKIM
//
//  Created by chzy on 2022/2/17.
//

import Foundation
import RKHandyJSON

@objc class DemoNoticeModel: NSObject, HandyJSON {
    public var title: String?
    public var content: String?
    required public override init() {}
}
