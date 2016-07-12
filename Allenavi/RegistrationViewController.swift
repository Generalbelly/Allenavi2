//
//  RegistrationViewController.swift
//  Allenavi
//
//  Created by ShimmenNobuyoshi on 2016/06/21.
//  Copyright © 2016年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit
import Eureka

class RegistrationViewController: FormViewController {

    let cellAlpha: CGFloat = 0.5
    var formCellBackgroundColor: UIColor?
    var formTextColor: UIColor?
    var resToRegister: Place?
    var delegate: NPVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createForm()
 
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController!.navigationBar.tintColor = UIColor.hex("EAEAEA", alpha: 1.0)
        self.formTextColor = UIColor.blackColor()
        self.formCellBackgroundColor = UIColor.whiteColor()
    }

    func createForm() {
        form +++ Section() {_ in }
            <<< TextRow("newrestaurant") { row in
                row.title = "レストラン名"
                }.cellSetup { cell, row in
                    cell.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(self.cellAlpha)
                }.cellUpdate { cell, row in
                    cell.textLabel?.textColor = self.formTextColor
                    cell.detailTextLabel?.textColor = self.formTextColor
            }
            <<< PhoneRow("newphone") { row in
                row.title = "電話番号"
                row.placeholder = "オプション"
                }.cellSetup { cell, row in
                    cell.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(self.cellAlpha)
                }.cellUpdate { cell, row in
                    cell.textLabel?.textColor = self.formTextColor
                    cell.detailTextLabel?.textColor = self.formTextColor
            }
            <<< TextRow("newaddress") { row in
                row.title = "住所"
                row.placeholder = "オプション"
                }.cellSetup { cell, row in
                    cell.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(self.cellAlpha)
                }.cellUpdate { cell, row in
                    cell.textLabel?.textColor = self.formTextColor
                    cell.detailTextLabel?.textColor = self.formTextColor
            }
            <<< ButtonRow() { row in
                row.title = "新規登録"
                }.cellSetup { cell, row in
                    cell.backgroundColor = UIColor.hex("F98C87", alpha: 1.0)
                    cell.tintColor = UIColor.whiteColor()
                }.onCellSelection { cell, row in
                    self.buttonTapped(self)
            }
    }
    
    func buttonTapped(sender: AnyObject) {
        let rawDict = self.form.values()
        let newres = rawDict["newrestaurant"] as? String ?? ""
        let newphone = rawDict["newphone"] as? String ?? ""
        let newaddress = rawDict["newaddress"] as? String ?? ""
        let place = Place()
        place.new = true
        place.name = newres
        place.phoneNumber = newphone
        place.address = newaddress
        self.resToRegister = place
        delegate?.passTheAnswer(place)
        let vc = self.navigationController?.viewControllers[1] as! SubmittingFormViewController
        vc.restaurant = place
        self.navigationController?.popToViewController(vc, animated: true)
    }
}
