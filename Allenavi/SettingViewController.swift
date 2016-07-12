//
//  SettingViewController.swift
//  Allenavi
//
//  Created by ShimmenNobuyoshi on 2016/02/22.
//  Copyright © 2016年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit
import Eureka
import Foundation
import FBSDKCoreKit
import FBSDKLoginKit
import SVProgressHUD
import Firebase

class SettingViewController: FormViewController, FBAuthViewControllerDelegate {

    let cellAlpha: CGFloat = 1.0
    var formCellBackgroundColor: UIColor?
    var formTextColor: UIColor?
    var userLogin = false
    let loginManager = FBSDKLoginManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = UIColor.hex("EAEAEA", alpha: 1.0)
        self.formTextColor = UIColor.blackColor()
        self.formCellBackgroundColor = UIColor.whiteColor().colorWithAlphaComponent(self.cellAlpha)
        self.tableView?.rowHeight = 44
        if FIRAuth.auth()?.currentUser != nil {
           self.userLogin = true
        }
        self.createSettingUI()
    }
    
    func createSettingUI() {
        form +++ Section()
            <<< ButtonRow("allergies") { row in
                row.title = "あなたのアレルギー"
                row.presentationMode = .SegueName(segueName: "showAVC", completionCallback: nil)
                }
                .onCellSelection { cell in
                }
                .cellSetup { cell, row in
                    cell.textLabel?.textAlignment = .Left
                    cell.backgroundColor = self.formCellBackgroundColor
                }.cellUpdate { cell, row in
                    cell.textLabel?.textColor = self.formTextColor
                    cell.detailTextLabel?.textColor = self.formTextColor
            }
            <<< PushRow<String>("service") { row in
                row.title = "アレなびについて"
                row.presentationMode = .SegueName(segueName: "show", completionCallback: nil)
                }
                .onCellSelection { cell in
                }
                .cellSetup { cell, row in
                    cell.backgroundColor = self.formCellBackgroundColor
                }.cellUpdate { cell, row in
                    cell.textLabel?.textColor = self.formTextColor
                    cell.detailTextLabel?.textColor = self.formTextColor
            }
            <<< PushRow<String>("TOS") { row in
                row.title = "利用規約"
                row.presentationMode = .SegueName(segueName: "show", completionCallback: nil)
                }.cellSetup { cell, row in
                    cell.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(self.cellAlpha)
                }.cellUpdate { cell, row in
                    cell.textLabel?.textColor = self.formTextColor
                    cell.detailTextLabel?.textColor = self.formTextColor
            }
            <<< PushRow<String>("プライバシーポリシー") { row in
                row.title = "プライバシーポリシー"
                row.presentationMode = .SegueName(segueName: "show", completionCallback: nil)
                }.cellSetup { cell, row in
                    cell.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(self.cellAlpha)
                }.cellUpdate { cell, row in
                    cell.textLabel?.textColor = self.formTextColor
                    cell.detailTextLabel?.textColor = self.formTextColor
            }
            <<< ButtonRow("login") {
                    if userLogin {
                        $0.title = "ログアウト"
                    } else {
                        $0.title = "ログイン"
                    }
                }
                .onCellSelection {  cell, row in
                    if row.title == "ログアウト" {
                        try! FIRAuth.auth()!.signOut()
                        FirebaseClient.sharedInstance.user = nil
                        row.title = "ログイン"
                        row.updateCell()
                        self.navigationController?.popToRootViewControllerAnimated(true)
                    } else {
                        self.performSegueWithIdentifier("login", sender: self)
                    }
                }
        }
    
    func FBLoginResult(didLogin: Bool) {
        guard let row: ButtonRow = self.form.rowByTag("login") else { return }
        if didLogin {
            row.title = "ログアウト"
        }
        row.updateCell()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let dv = segue.destinationViewController as? FBAuthViewController {
            dv.delegate = self
        } else {
            guard let row = sender! as? PushRow<String> else { return }
            SVProgressHUD.show()
            let title = row.title!
            let dvc = segue.destinationViewController as? DetailViewController
            switch title {
            case "アレなびについて":
                dvc?.pageUrl = "http://unbouncepages.com/yonder-9654/"
            case "利用規約":
                dvc?.pageUrl = "http://unbouncepages.com/good-bank-714/"
            case "プライバシーポリシー":
                dvc?.pageUrl = "http://unbouncepages.com/good-bank-716/"
            default:
                break
            }
        }
    }
}
