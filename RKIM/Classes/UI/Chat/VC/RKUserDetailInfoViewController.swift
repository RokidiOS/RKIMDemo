//
//  RKUserDetailInfoViewController.swift
//  RKIM
//
//  Created by chzy on 2022/2/23.
//  用户详情页面

import UIKit
import RKIMCore
import Kingfisher
import SnapKit
import RKIBaseView

class RKUserDetailInfoViewController: RKBaseViewController {

    var info = RKIMUser() {
        didSet {
            infoLabel.text = info.toJSONString()
            avatar.kf.setImage(with: URL(string: info.headPortrait))
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubViews([avatar, infoLabel])
        avatar.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 80, height: 80))
            make.centerX.equalToSuperview()
            make.top.equalTo(50)
        }
        infoLabel.snp.makeConstraints { make in
            make.width.equalToSuperview().offset(-40)
            make.top.equalTo(avatar.snp_bottom)
            make.centerX.equalToSuperview()
        }
        infoLabel.font = .systemFont(ofSize: 16)
        infoLabel.numberOfLines = 0
        infoLabel.setContentHuggingPriority(.required, for: .vertical)
    }
    
    lazy var avatar = UIImageView()
    lazy var infoLabel = UILabel()


}
