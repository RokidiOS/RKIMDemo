//
//  DatePicker.swift
//  RKIM
//
//  Created by chzy on 2022/3/8.
//

import Foundation
import UIKit

protocol DatePickerDelegate: NSObjectProtocol {
    func pickerSure(date: Date)
}

class DatePickerView {
    
    weak var delegate: DatePickerDelegate?
    
    init(_ view: UIView) {
        view.addSubViews([pickerView, cancelButton, sureButton])
        pickerView.backgroundColor = UIColor.white
        pickerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(120)
            make.top.equalTo(view.snp_bottom)
        }
        
        cancelButton.snp.makeConstraints { make in
            make.left.equalTo(pickerView)
            make.height.equalTo(40)
            make.bottom.equalTo(pickerView.snp_top)
            make.width.equalToSuperview().multipliedBy(0.5)
        }
        
        sureButton.snp.makeConstraints { make in
            make.right.equalTo(pickerView)
            make.height.equalTo(40)
            make.bottom.equalTo(pickerView.snp_top)
            make.width.equalToSuperview().multipliedBy(0.5)
        }
        cancelButton.backgroundColor = .white
        sureButton.backgroundColor = .white
        view.layoutIfNeeded()
    }
    
    func show(_ view: UIView) {
        pickerView.snp.remakeConstraints { make in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(120)
        }
        
        UIView.animate(withDuration: 0.3) {
            view.layoutIfNeeded()
        }
    }
    
    @objc private func hidden() {
        guard let view = pickerView.superview else { return }
        pickerView.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(120)
            make.top.equalTo(view.snp_bottom).offset(50)
        }
        
        UIView.animate(withDuration: 0.3) {
            view.layoutIfNeeded()
        }
    }
    
    @objc private func sure() {
        delegate?.pickerSure(date: pickerView.date)
        hidden()
    }
    
    lazy var pickerView: UIDatePicker = {
        let pickerView = UIDatePicker(frame: CGRect.zero)
        pickerView.datePickerMode = .dateAndTime
        pickerView.maximumDate = Date()
        return pickerView
    }()
    
    lazy var cancelButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("取消", for: .normal)
        btn.setTitleColor(.blue, for: .normal)
        btn.addTarget(self, action: #selector(hidden), for: .touchUpInside)
        return btn
    }()
    
    lazy var sureButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("确定", for: .normal)
        btn.setTitleColor(.blue, for: .normal)
        btn.addTarget(self, action: #selector(sure), for: .touchUpInside)
        return btn
    }()
}
