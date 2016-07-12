//
//  SubmittingFormViewController.swift
//  Allenavi
//
//  Created by ShimmenNobuyoshi on 2016/01/31.
//  Copyright © 2016年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit
import Eureka
import Foundation
import SVProgressHUD
import Firebase
import Photos

protocol SubmittingFormVCDelegate {
    func submissionCompleted()
}

class SubmittingFormViewController: FormViewController, NPVCDelegate, PTVCDelegate {

    var delegate: SubmittingFormVCDelegate?
    var asset: PHAsset? {
        didSet {
            self.createImageFromAsset(self.asset!) { image in
                self.setupImageAsBgView(image)
                self.image = image
            }
        }
    }
    var image: UIImage?
    var scrollView = UIScrollView()
    let cellAlpha: CGFloat = 0.5
    var formCellBackgroundColor: UIColor?
    var formTextColor: UIColor?
    var restaurant: Place? {
        didSet {
            if restaurant != nil {
                guard let row: PushRow<String> = self.form.rowByTag("restaurantName") else { return }
                row.value = self.restaurant?.name
                row.updateCell()
            }
        }
    }
    var allergies = [String]() {
        didSet {
            if allergies.count > 0 {
                guard let row: MultipleSelectorRow<String> = self.form.rowByTag("allergies") else { return }
                row.value = Set([String](self.allergies))
                row.updateCell()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createForm()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController!.navigationBar.tintColor = UIColor.hex("EAEAEA", alpha: 1.0)
        self.formTextColor = UIColor.blackColor()
        self.formCellBackgroundColor = UIColor.whiteColor().colorWithAlphaComponent(self.cellAlpha)
    }
    
    func setupImageAsBgView(image: UIImage) {
        let bgView = UIView(frame: self.view.bounds)
        let imageView = UIImageView(image: image)
        imageView.contentMode = .ScaleAspectFill
        imageView.frame = CGRectMake(0, 0, self.view.bounds.width, self.view.bounds.height)
        bgView.addSubview(imageView)
        self.tableView!.backgroundView = bgView
    }
    
    func createImageFromAsset(asset: PHAsset, completionHandler: UIImage -> Void) {
        let manager = PHImageManager.defaultManager()
        let options = PHImageRequestOptions()
        options.resizeMode = PHImageRequestOptionsResizeMode.Exact
        options.deliveryMode = .HighQualityFormat
        manager.requestImageForAsset(asset, targetSize: PHImageManagerMaximumSize, contentMode: .AspectFit, options: options) { (result, info) in
            completionHandler(result!)
        }
    }

    func showAlert(notFilledOut: [String]) {
        var items = [String]()
        var alertController: UIAlertController?
        if notFilledOut.contains("restaurantName") {
            items.append("レストラン名")
        }
        if notFilledOut.contains("allergies") {
            items.append("アレルギー情報")
        }
        let message = items.joinWithSeparator("、")
        alertController = UIAlertController(title: "未入力の項目があります", message: "\(message)を入れてください", preferredStyle: .Alert)
        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
            alertController!.dismissViewControllerAnimated(true, completion: nil)
        }
        alertController!.addAction(OKAction)
        self.presentViewController(alertController!, animated: true, completion: nil)
    }
    
    func buttonTapped(sender: AnyObject) {
        let rawDict = self.form.values()
        let comment = rawDict["comment"] as? String ?? ""
        let allergies = rawDict["allergies"] as! Set<String>?
        var dict = ["allergies": allergies, "comment": comment, "place": self.restaurant] as [String: AnyObject?]
        var notFilledOut = [String]()
        for (k, v) in dict {
            if v == nil {
                if k == "restaurantName" || k == "allergies" {
                    notFilledOut.append(k)
                }
            }
        }
        guard notFilledOut.count == 0 else {
            self.showAlert(notFilledOut)
            return
        }
        dict["allergies"] = self.allergies
        dict["image"] = self.image
        if self.restaurant!.dbId != "" {
            FirebaseClient.sharedInstance.save(.AddPost, info: dict as! [String: AnyObject])
        } else {
            FirebaseClient.sharedInstance.save(.AddResAndPost, info: dict as! [String: AnyObject])
        }
        self.delegate?.submissionCompleted()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func createForm() {
        form +++ Section() {
            $0.header = HeaderFooterView<UIView>(HeaderFooterProvider.Class)
            $0.header!.height = { CGFloat(UIScreen.mainScreen().bounds.height - 64 - (44 * 5.5)) }
            }
            <<< PushRow<String>("restaurantName") { row in
                row.title = "レストラン名"
                row.presentationMode = .SegueName(segueName: "nearVC", completionCallback: nil)
                }
                .cellSetup { cell, row in
                    cell.backgroundColor = self.formCellBackgroundColor
                }.cellUpdate { cell, row in
                    cell.textLabel?.textColor = self.formTextColor
                    cell.detailTextLabel?.textColor = self.formTextColor
            }
            <<< MultipleSelectorRow<String>("allergies") { row in
                row.title = "食事した人のアレルギー"
                row.presentationMode = .SegueName(segueName: "plainTVC", completionCallback: nil)
                }.cellSetup { cell, row in
                    cell.backgroundColor = self.formCellBackgroundColor
                }.cellUpdate { cell, row in
                    cell.textLabel?.textColor = self.formTextColor
                    cell.detailTextLabel?.textColor = self.formTextColor
            }
            <<< TextAreaRow("comment") {
                $0.placeholder = "コメント（オプション）"
                $0.value = ""
                }.cellSetup { cell, row in
                    cell.textView.backgroundColor = UIColor.clearColor()
                    cell.backgroundColor = self.formCellBackgroundColor
                }.cellUpdate { cell, row in
                    cell.textView.textColor = self.formTextColor
            }
            <<< ButtonRow() { row in
                row.title = "投稿する"
                }.cellSetup { cell, row in
                    cell.backgroundColor = UIColor.hex("F98C87", alpha: 1.0)
                    cell.tintColor = UIColor.whiteColor()
                }.onCellSelection { cell, row in
                    self.buttonTapped(self)
            }
    }

    func passTheAnswer(answer: Place) {
        self.restaurant = answer
    }
    
    func passTheAnswers(answers: [String]) {
        self.allergies = answers
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let npvc = segue.destinationViewController as? NearPlacesViewController {
            if self.restaurant != nil {
                npvc.chosenPlace = self.restaurant
            }
            npvc.delegate = self
        }
        if let ptvc = segue.destinationViewController as? PlainTalbeViewController {
            if self.allergies.count < 0 {
                ptvc.chosenAllergies = self.allergies
            }
            ptvc.delegate = self
        }
    }
    
}
