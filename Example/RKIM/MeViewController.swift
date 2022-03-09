//
//  MeViewController.swift
//  RKIM_Example
//
//  Created by chzy on 2022/2/23.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import RKIM
import Kingfisher
import RKIMCore

class MeViewController: UIViewController {

    @IBOutlet weak var avator: UIImageView!
    
    @IBOutlet weak var infoLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let info = DemoUserCenter.userInfo
        avator.kf.setImage(with: URL(string: info.headPortrait))
        infoLabel.text =  info.realName + "|" + info.companyName + " |"
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
