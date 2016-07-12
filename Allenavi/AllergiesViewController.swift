//
//  AllergiesViewController.swift
//  Allenavi
//
//  Created by ShimmenNobuyoshi on 2016/03/17.
//  Copyright © 2016年 ShimmenNobuyoshi. All rights reserved.
//

import Foundation
import UIKit

protocol AllergensViewControllerDelegate {
    func allergenChosen(allergens: [String])
}

class AllergensViewController: UIViewController, UICollectionViewDataSource, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout {
    
    let userDefaults = NSUserDefaults.standardUserDefaults()
    @IBAction func completeTapped(sender: AnyObject) {
        if self.selectedAllergies.count == 0 {
            self.showAlert()
        } else {
            self.dismissVC()
        }
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    var gridThumbnailSize: CGSize?
    var delegate: AllergensViewControllerDelegate?
    let space: CGFloat = 10
    var selectedAllergies = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let userAllergies = self.userDefaults.valueForKey("yourAllergies") as? [String] {
            self.selectedAllergies = userAllergies.map() { item -> String in
                var key = ""
                for (k, v) in Constants.allergens {
                    if v == item {
                        key = k
                        break
                    }
                }
                return key
            }
        }
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.allowsMultipleSelection = true
        UIApplication.sharedApplication().statusBarHidden = true
        
    }
    
    func dismissVC() {
        UIApplication.sharedApplication().statusBarHidden = false
        if (userDefaults.valueForKey("allergiesAsked") == nil) {
            userDefaults.setBool(true, forKey: "allergiesAsked")
        }
        let allergiesToSet = selectedAllergies.map() { key -> String in
            let value = Constants.allergens[key]
            return value!
        }
        userDefaults.setObject(allergiesToSet, forKey: "yourAllergies")
        userDefaults.synchronize()
        self.delegate?.allergenChosen(allergiesToSet)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func showAlert() {
        let alertController = UIAlertController(title: "アレルギーの未選択", message: "アレルギーを選択をしない場合、全てのレストランが表示されます。", preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "キャンセル", style: .Cancel) { (action) in
            alertController.dismissViewControllerAnimated(true, completion: nil)
        }
        alertController.addAction(cancelAction)
        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
            self.dismissVC()
        }
        alertController.addAction(OKAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }

    // UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Constants.keys.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCellWithReuseIdentifier("allergycell", forIndexPath: indexPath) as! AllergiesCollectionViewCell
        let allergy = Constants.keys[indexPath.item]
        for item in self.selectedAllergies {
            if item == allergy {
                cell.selected = true
                collectionView.selectItemAtIndexPath(indexPath, animated: true, scrollPosition: .None)
                break
            }
        }
        cell.imageView.image = nil
        cell.allergyName.hidden = true
        cell.allergyNameWithImage.hidden = true
        cell.layer.cornerRadius = self.gridThumbnailSize!.height / 2
        cell.layer.borderColor = UIColor.hex("F69A4A", alpha: 1.0).CGColor
        cell.layer.borderWidth = 2.0
        if let foodImage = UIImage(named: Constants.allergens[Constants.keys[indexPath.item]]!) {
            cell.imageView.image = foodImage
            cell.allergyNameWithImage.text = allergy
            cell.allergyNameWithImage.hidden = false
        } else {
            cell.allergyName.text = allergy
            cell.allergyName.hidden = false
        }
        if cell.selected {
            self.changeCellColor(cell, selected: true)
        } else {
            self.changeCellColor(cell, selected: false)
        }
        return cell
    }
    
    func changeCellColor(cell: AllergiesCollectionViewCell, selected: Bool) {
        if selected {
            cell.imageView.tintColor = UIColor.whiteColor()
            cell.contentView.backgroundColor = UIColor.hex("F69A4A", alpha: 1.0)
            cell.allergyName.textColor = UIColor.whiteColor()
            cell.allergyNameWithImage.textColor = UIColor.whiteColor()
            if cell.imageView.image == UIImage(named: "peanuts") {
                cell.imageView.image = UIImage(named: "peanuts2")
            } else if cell.imageView.image == UIImage(named: "abalone") {
                cell.imageView.image = UIImage(named: "abalone2")
            }
        } else {
            cell.contentView.backgroundColor = UIColor.clearColor()
            cell.imageView.tintColor = UIColor.hex("F69A4A", alpha: 1.0)
            cell.allergyName.textColor = UIColor.darkGrayColor()
            cell.allergyNameWithImage.textColor = UIColor.darkGrayColor()
            if cell.imageView.image == UIImage(named: "peanuts2") {
                cell.imageView.image = UIImage(named: "peanuts")
            } else if cell.imageView.image == UIImage(named: "abalone2") {
                cell.imageView.image = UIImage(named: "abalone")
            }
        }
    }
    
    // UICollectionViewDelegate
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! AllergiesCollectionViewCell
        self.changeCellColor(cell, selected: true)
        self.selectedAllergies.append(Constants.keys[indexPath.item])
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! AllergiesCollectionViewCell
        self.changeCellColor(cell, selected: false)
        let allergy = Constants.keys[indexPath.item]
        for (index, item) in self.selectedAllergies.enumerate() {
            if allergy.isEqual(item) {
                self.selectedAllergies.removeAtIndex(index)
            }
        }
    }
    
    // UICollectionViewDelegateFlowLayout
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let width = (UIScreen.mainScreen().bounds.width - (self.space * 4)) / 3
        self.gridThumbnailSize = CGSize(width: width, height: width)
        return  self.gridThumbnailSize!
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return self.space
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return self.space
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(self.space, self.space, self.space, self.space)
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "header", forIndexPath: indexPath)
        let label = UILabel(frame: CGRect(origin: CGPointZero, size: CGSize(width: collectionView.bounds.width - 30, height: 100)))
        label.numberOfLines = 0
        let boldText = "下記よりアレルギーを選択してください。"
        let normalText  = "\nアレルギーは設定メニューよりいつでも変更可能です。\n尚、今後、対応アレルギーを増やしていく予定です。"
        let nattrs = [NSFontAttributeName: label.font.fontWithSize(14)]
        let normalString = NSMutableAttributedString(string:normalText, attributes: nattrs)
        let battrs = [NSFontAttributeName : UIFont.boldSystemFontOfSize(14)]
        let boldString = NSMutableAttributedString(string:boldText, attributes: battrs)
        boldString.appendAttributedString(normalString)
        label.attributedText = boldString
        label.center = header.center
        header.addSubview(label)
        return header
    }

 }
