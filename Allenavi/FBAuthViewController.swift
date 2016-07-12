//
//  FBAuthViewController.swift
//  Allenavi
//
//  Created by ShimmenNobuyoshi on 2016/02/21.
//  Copyright © 2016年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase
import SVProgressHUD

protocol FBAuthViewControllerDelegate {
    func FBLoginResult(didLogin: Bool)
}

class FBAuthViewController: UIViewController {

    let loginManager = FBSDKLoginManager()
    var delegate: FBAuthViewControllerDelegate?
    var emailTextField: UITextField! {
        didSet {
            emailTextField.tag = 0
            emailTextField.addTarget(self, action: #selector(FBAuthViewController.checkTextField(_:)), forControlEvents: .EditingChanged)
            emailTextField.delegate = self
        }
    }
    var passwordTextField: UITextField! {
        didSet {
            passwordTextField.tag = 1
            passwordTextField.addTarget(self, action: #selector(FBAuthViewController.checkTextField(_:)), forControlEvents: .EditingChanged)
            passwordTextField.delegate = self
        }
    }
    var forgetPasswordLabel: UILabel!
    var FBLoginButton: UIButton!
    var emailLoginButton: UIButton!
    var loginButton: UIButton!
    var inputDone: Bool? {
        didSet {
            guard self.inputDone != nil && self.loginButton != nil else { return }
            if inputDone! {
                self.loginButton.backgroundColor = UIColor.hex("F98C87", alpha: 1.0)
                self.loginButton.enabled = true
            } else {
                self.loginButton.backgroundColor = UIColor.hex("F98C87", alpha: 0.5)
                self.loginButton.enabled = false
            }
        }
    }
    var signupOrsigninLabel: UILabel!
    var signupScreenShown = true
    var emailLoginSelected = false
    var navbar: UINavigationBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let bgView = UIImageView(image: UIImage(named: "loginScreen"))
        bgView.frame = self.view.frame
        self.view.addSubview(bgView)
        self.setupFBlogin()
        self.setupEmailPasswordLogin()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        UINavigationBar.appearance().translucent = true
        self.configureUI()
        self.subscribeToKeyboardNotification()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
        UINavigationBar.appearance().translucent = false
    }
    
    func configureUI() {
        navbar = UINavigationBar(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width, 50))
        navbar.tintColor = UIColor.hex("eaeaea", alpha: 1.0)
        navbar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        navbar.shadowImage = UIImage()
        self.view.addSubview(navbar)
        let closeIcon = UIImage(named: "Close")
        let closeButton = UIBarButtonItem(image: closeIcon, style: .Plain, target: self, action: #selector(FBAuthViewController.closeTapped(_:)))
        let navItem = UINavigationItem(title: "")
        navItem.leftBarButtonItem = closeButton
        navbar.items = [navItem]
    }
    
    func setupFBlogin() {
        let lbH: CGFloat = 44
        let lbY = self.view.bounds.height - (lbH * 4)
        FBLoginButton = UIButton(frame: CGRect(x: 15, y: lbY, width: self.view.bounds.width - 30, height: lbH))
        FBLoginButton.backgroundColor = UIColor.hex("3b5998", alpha: 1.0)
        self.view.addSubview(FBLoginButton)
        FBLoginButton.setTitle("Facebookで新規登録", forState: .Normal)
        FBLoginButton.addTarget(self, action: #selector(FBAuthViewController.FBLoginButtonTapped(_:)), forControlEvents: .TouchUpInside)
        self.view.addSubview(FBLoginButton)
    }
    
    func changeToLoginScreen(sender: AnyObject) {
        if signupScreenShown {
            self.FBLoginButton.setTitle("Facebookでログイン", forState: .Normal)
            self.emailLoginButton.setTitle("メールアドレスでログイン", forState: .Normal)
            self.loginButton.setTitle("ログイン", forState: .Normal)
            self.signupOrsigninLabel.text = "新規登録はこちら"
            signupScreenShown = false
        } else {
            self.FBLoginButton.setTitle("Facebookで新規登録", forState: .Normal)
            self.emailLoginButton.setTitle("メールアドレスで新規登録", forState: .Normal)
            self.loginButton.setTitle("新規登録", forState: .Normal)
            self.signupOrsigninLabel.text = "アカウントをすでにお持ちの方はこちら"
            signupScreenShown = true
        }
    }
    
    func setupEmailPasswordLogin() {
        self.inputDone = false
        self.emailLoginButton = UIButton(frame: self.FBLoginButton.frame)
        self.emailLoginButton.setTitle("メールアドレスで新規登録", forState: .Normal)
        self.emailLoginButton.backgroundColor = UIColor.hex("F98C87", alpha: 1.0)
        self.emailLoginButton.frame.origin.y = FBLoginButton.frame.origin.y + FBLoginButton.frame.height + 10
        self.emailLoginButton.addTarget(self, action: #selector(FBAuthViewController.emailLoginButtonTapped(_:)), forControlEvents: .TouchUpInside)
        self.view.addSubview(self.emailLoginButton)
        
        self.emailTextField = UITextField(frame: self.FBLoginButton.frame)
        self.emailTextField.keyboardType = .EmailAddress
        self.setTextFieldBasicAttributes(self.emailTextField, placeholder: "メールアドレス")
        self.view.addSubview(self.emailTextField)
        
        self.passwordTextField = UITextField(frame: self.emailLoginButton.frame)
        self.passwordTextField.secureTextEntry = true
        self.setTextFieldBasicAttributes(self.passwordTextField, placeholder: "パスワード")
        self.view.addSubview(self.passwordTextField)
        
        self.loginButton = UIButton(frame: self.emailLoginButton.frame)
        self.loginButton.setTitle("新規登録", forState: .Normal)
        self.loginButton.frame.origin.y = emailLoginButton.frame.origin.y + emailLoginButton.frame.height + 10
        self.loginButton.backgroundColor = UIColor.hex("F98C87", alpha: 0.5)
        self.loginButton.addTarget(self, action: #selector(FBAuthViewController.loginButtonTapped(_:)), forControlEvents: .TouchUpInside)
        self.loginButton.hidden = true
        self.view.addSubview(self.loginButton)

        self.signupOrsigninLabel = UILabel(frame: self.loginButton.frame)
        self.setLabelBasicAttributes(self.signupOrsigninLabel, text: "アカウントをすでにお持ちの方はこちら")
        let tgr = UITapGestureRecognizer(target: self, action: #selector(FBAuthViewController.changeToLoginScreen(_:)))
        self.signupOrsigninLabel.addGestureRecognizer(tgr)
        self.view.addSubview(signupOrsigninLabel)
        
        self.forgetPasswordLabel = UILabel(frame: CGRect(origin: CGPoint(x: 0, y: self.FBLoginButton.frame.origin.y - self.FBLoginButton.frame.height), size: self.FBLoginButton.frame.size))
        self.setLabelBasicAttributes(self.forgetPasswordLabel, text: "パスワードをお忘れの方はこちら")
        self.forgetPasswordLabel.hidden = true
        let ftgr = UITapGestureRecognizer(target: self, action: #selector(FBAuthViewController.forgetPasswordTapped(_:)))
        self.forgetPasswordLabel.addGestureRecognizer(ftgr)
        self.view.addSubview(forgetPasswordLabel)
        
    }
    
    func forgetPasswordTapped(sender: AnyObject) {
        self.performSegueWithIdentifier("reset", sender: self)
    }
    
    func setLabelBasicAttributes(label: UILabel, text: String) {
        label.numberOfLines = 1
        label.text = text
        label.textAlignment = NSTextAlignment.Center
        label.font = UIFont.systemFontOfSize(14)
        label.userInteractionEnabled = true
    }

    func setTextFieldBasicAttributes(textField: UITextField, placeholder: String) {
        textField.placeholder = placeholder
        textField.clearButtonMode = .WhileEditing
        textField.textAlignment = .Center
        textField.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.5)
        textField.hidden = true
    }
    
    func loginButtonTapped(sender: AnyObject) {
        let button = sender as! UIButton
        let buttonTitle = button.currentTitle
        let email = self.emailTextField.text
        let password = self.passwordTextField.text
        guard email!.isValidEmail else {
            self.showAlert("入力内容エラー", message: "有効なメールアドレスをご入力ください。")
            return
        }
        SVProgressHUD.show()
        if buttonTitle == "ログイン" {
            FIRAuth.auth()?.signInWithEmail(email!, password: password!) { (user, error) in
                if error != nil {
                    self.errorChecker(error!)
                } else {
                    self.loginDidSucceed(user!)
                }
            }
        } else {
            FIRAuth.auth()?.createUserWithEmail(email!, password: password!) { (user, error) in
                if error != nil {
                    self.errorChecker(error!)
                } else {
                    self.loginDidSucceed(user!)
                }
            }
        }
    }
    
    func errorChecker(error: NSError) {
        if SVProgressHUD.isVisible() {
            SVProgressHUD.dismiss()
        }
        if let errorCode = FIRAuthErrorCode(rawValue: error.code) {
            print(error.userInfo)
            switch (errorCode) {
            case .ErrorCodeNetworkError:
                self.showAlert("エラーの発生", message: "通信状況をご確認ください。")
                print("Handle network error")
            case .ErrorCodeUserNotFound:
                self.showAlert("ログインの失敗", message: "アカウントが存在しません。")
                print("Handle invalid user")
            case .ErrorCodeInvalidEmail:
                self.showAlert("入力内容エラー", message: "メールアドレスが正しくありません。")
                print("Handle invalid email")
            case .ErrorCodeWrongPassword:
                self.showAlert("入力内容エラー", message: "パスワードが正しくありません。")
                print("Handle invalid password")
            case .ErrorCodeEmailAlreadyInUse:
                self.showAlert("新規登録の失敗", message: "メールアドレスが既に使用されています。")
                print("Email address is already in use.")
            case .ErrorCodeWeakPassword:
                self.showAlert("新規登録の失敗", message: "パスワードは6文字以上のものを設定してください")
            default:
                if self.signupScreenShown {
                    self.showAlert("新規登録の失敗", message: "もう一度やり直してください。")
                } else {
                    self.showAlert("ログインの失敗", message: "もう一度やり直してください。")
                }
                print("Handle default situation")
            }
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
    
    func loginDidSucceed(user: FIRUser) {
        if SVProgressHUD.isVisible() {
            SVProgressHUD.dismiss()
        }
        if !self.emailLoginSelected {
            self.loginManager.logOut()
        }
        self.delegate?.FBLoginResult(true)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func emailLoginButtonTapped(sender: AnyObject) {
        self.switchScreen(true)
    }
    
    func switchScreen(emailLoginSelected: Bool) {
        self.emailLoginSelected = emailLoginSelected
        self.FBLoginButton.hidden = emailLoginSelected
        self.emailLoginButton.hidden = emailLoginSelected
        self.emailTextField.hidden = !emailLoginSelected
        self.passwordTextField.hidden = !emailLoginSelected
        self.loginButton.hidden = !emailLoginSelected
        self.signupOrsigninLabel.hidden = emailLoginSelected
        self.forgetPasswordLabel.hidden = !emailLoginSelected
    }
    
    func FBLoginButtonTapped(sender: AnyObject) {
        loginManager.logInWithReadPermissions(["email", "public_profile"], fromViewController: self) {
            (facebookResult, facebookError) -> Void in
            if facebookError != nil {
                print("Facebook login failed. Error \(facebookError)")
            } else if facebookResult.isCancelled {
                print("Facebook login was cancelled.")
            } else {
                let credential = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
                FIRAuth.auth()?.signInWithCredential(credential) { (user, error) in
                    if error != nil {
                        if !self.signupScreenShown {
                            self.showAlert("ログインの失敗", message: "もう一度やり直してください。")
                        } else {
                            self.showAlert("新規登録の失敗", message: "もう一度やり直してください。")
                        }
                    } else {
                        self.loginDidSucceed(user!)
                    }
                }
            }
        }
    }
    
    func closeTapped(sender: AnyObject) {
        if !self.emailLoginSelected {
            self.dismissViewControllerAnimated(true, completion: nil)
            self.delegate?.FBLoginResult(false)
        } else {
            if self.view.frame.origin.y < 0 {
                if self.emailTextField.isFirstResponder() {
                    self.view.endEditing(true)
                } else {
                    self.view.endEditing(true)
                }
            }
            self.switchScreen(false)
        }
    }
}

extension FBAuthViewController: UITextFieldDelegate {
    
    func subscribeToKeyboardNotification() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FBAuthViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FBAuthViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        self.view.frame.origin.y = -getKeyboardHeight(notification)
        self.navbar.frame.origin.y = getKeyboardHeight(notification)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        self.view.frame.origin.y = CGFloat(0)
        self.navbar.frame.origin.y = CGFloat(0)
    }
    
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.CGRectValue().height
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func checkTextField(sender: AnyObject) {
        let textField = sender as! UITextField
        let tag = textField.tag
        let text = textField.text
        if (tag == 0 && !self.passwordTextField.text!.isEmpty) || (tag == 1 && !self.emailTextField.text!.isEmpty) {
            if text != "" {
                if !self.inputDone! {
                    self.inputDone = true
                }
            } else {
                if self.inputDone! {
                    self.inputDone = false
                }
            }
        }
    }

}
