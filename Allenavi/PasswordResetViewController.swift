//
//  PasswordResetViewController.swift
//  Allenavi
//
//  Created by ShimmenNobuyoshi on 2016/06/19.
//  Copyright © 2016年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit
import Foundation
import Firebase
import SVProgressHUD

class PasswordResetViewController: UIViewController {

    var navbar: UINavigationBar!
    @IBOutlet weak var emailTextField: UITextField! {
        didSet {
            self.emailTextField.addTarget(self, action: #selector(PasswordResetViewController.checkTextField(_:)), forControlEvents: .EditingChanged)
        }
    }
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var resetButton: UIButton!
    @IBAction func resetButtonTapped(sender: AnyObject) {
        let email = emailTextField.text
        guard email!.isValidEmail else {
            self.showAlert("入力内容エラー", message: "有効なメールアドレスをご入力ください。")
            return
        }
        SVProgressHUD.show()
        FIRAuth.auth()?.sendPasswordResetWithEmail(email!) { error in
            dispatch_async(dispatch_get_main_queue()) {
                SVProgressHUD.dismiss()
                if error != nil {
                     self.showAlert("エラー", message: error!.localizedDescription)
                } else {
                    self.label.text = "リセット用のリンクを送信しました。リンクより新しいパスワードを設定してください。"
                    self.emailTextField.hidden = true
                    self.emailTextField.resignFirstResponder()
                    self.resetButton.hidden = true
                    self.view.setNeedsDisplay()
                }
            }
        }
    }
    var inputDone = false {
        didSet {
            if inputDone {
                self.resetButton.alpha = 1.0
                self.resetButton.enabled = true
            } else {
                self.resetButton.alpha = 0.5
                self.resetButton.enabled = false
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navbar = UINavigationBar(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width, 50))
        navbar.tintColor = UIColor.hex("eaeaea", alpha: 1.0)
        navbar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        navbar.shadowImage = UIImage()
        self.view.addSubview(navbar)
        let closeIcon = UIImage(named: "Close")
        let closeButton = UIBarButtonItem(image: closeIcon, style: .Plain, target: self, action: #selector(PasswordResetViewController.closeTapped(_:)))
        let navItem = UINavigationItem(title: "")
        navItem.leftBarButtonItem = closeButton
        navbar.items = [navItem]
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.subscribeToKeyboardNotification()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    func checkTextField(sender: AnyObject) {
        let textField = sender as! UITextField
        let text = textField.text
        if !self.emailTextField.text!.isEmpty {
            if text != "" {
                if !self.inputDone {
                    self.inputDone = true
                }
            } else {
                if self.inputDone {
                    self.inputDone = false
                }
            }
        } else {
            self.inputDone = false
        }
    }
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
            alertController.dismissViewControllerAnimated(true, completion: nil)
        }
        alertController.addAction(OKAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func closeTapped(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}

extension PasswordResetViewController: UITextFieldDelegate {
    
    func subscribeToKeyboardNotification() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FBAuthViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FBAuthViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        self.view.frame.origin.y -= 20
        self.navbar.frame.origin.y += 20
    }
    
    func keyboardWillHide(notification: NSNotification) {
        self.view.frame.origin.y = CGFloat(0)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
