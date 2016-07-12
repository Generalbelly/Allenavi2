//
//  AccountViewController.swift
//  Allenavi
//
//  Created by ShimmenNobuyoshi on 2016/03/22.
//  Copyright © 2016年 ShimmenNobuyoshi. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import Kingfisher
import DZNEmptyDataSet
import JTSImageViewController
import PhotosUI

class AccountViewController: UIViewController, UICollectionViewDataSource, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout, CamerarollViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            self.collectionView.delegate = self
            self.collectionView.dataSource = self
            self.collectionView.emptyDataSetSource = self
            self.collectionView.emptyDataSetDelegate = self
        }
    }
    var selectedPost: Post?
    @IBOutlet weak var nameLabel: UILabel! {
        didSet {
            let tgr = UITapGestureRecognizer(target: self, action: #selector(AccountViewController.nameLabelTapped(_:)))
            nameLabel!.userInteractionEnabled = true
            nameLabel!.addGestureRecognizer(tgr)
        }
    }
    @IBOutlet weak var allergiesLabel: UILabel! {
        didSet {
            let tgr2 = UITapGestureRecognizer(target: self, action: #selector(AccountViewController.allergiesLabelTapped(_:)))
            allergiesLabel!.userInteractionEnabled = true
            allergiesLabel!.addGestureRecognizer(tgr2)
            if let userAllergies = self.userDefaults.valueForKey("yourAllergies") as? [String] {
                if userAllergies.count > 0 {
                    let userAllergiesToShow = self.convertEnglishToJapanese(userAllergies)
                    allergiesLabel!.text = "アレルギー\n" + userAllergiesToShow.joinWithSeparator(", ")
                } else {
                    allergiesLabel!.text = "アレルギー\nなし"
                }
            }
        }
    }
    @IBOutlet weak var profileImageView: UIImageView! {
        didSet {
            self.profileImageView.contentMode = .ScaleAspectFit
            self.profileImageView.userInteractionEnabled = true
            let imageTgr = UITapGestureRecognizer(target: self, action: #selector(AccountViewController.imageViewTapped(_:)))
            self.profileImageView.addGestureRecognizer(imageTgr)
        }
    }
    var emptyState = false {
        didSet {
            if emptyState {
                self.collectionView.reloadData()
            }
        }
    }
    @IBOutlet weak var profileView: UIView!
    var user: FIRUser?
    var posts = [Post]()
    var userDefaults = NSUserDefaults()
    var width: CGFloat?
    let offset: CGFloat = 15
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.width = UIScreen.mainScreen().bounds.width / 3
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let user = FIRAuth.auth()?.currentUser {
            self.user = user
        } else {
            self.user = nil
        }
        self.setUserProfile()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.profileImageView.layer.cornerRadius = self.profileImageView.bounds.height / 2
        self.profileImageView.layer.masksToBounds = true
    }
    
    func setUserProfile() {
        if self.user != nil {
            let name = self.user!.displayName ?? "未設定"
            self.nameLabel!.text = "名前\n\(name)"
            if self.user!.photoURL != nil {
                self.profileImageView!.kf_setImageWithURL(self.user!.photoURL!, placeholderImage: nil, optionsInfo: nil, progressBlock: { receivedSize, totalSize in}, completionHandler: { image, error, cacheType, imageURL in
                    if image!.size.height > image!.size.width {
                        self.profileImageView!.contentMode = .ScaleAspectFill
                    }
                })
            } else {
                self.profileImageView!.image = UIImage(named: "NoImage")
            }
            self.profileImageView?.userInteractionEnabled = true
            FirebaseClient.sharedInstance.postsRef.child(user!.uid).observeEventType(.Value, withBlock: { snapshot in
                print("fetched")
                print(snapshot.value)
                if snapshot.exists() {
                    print(snapshot.value)
                    let value = snapshot.value as! [String: AnyObject]
                    let posts = value.map() { item -> Post in
                        let post = FirebaseClient.sharedInstance.createPost(item.1 as! [String : AnyObject])
                        return post
                    }
                    self.posts = posts
                    self.collectionView.reloadData()
                } else {
                    self.emptyState = true
                }
            })
        } else {
            self.nameLabel!.text = "名前\nゲストユーザ"
            if self.posts.count > 0 {
                self.posts.removeAll()
            }
            self.profileImageView?.image = UIImage(named: "NoImage")
            self.profileImageView?.userInteractionEnabled = false
            self.emptyState = true
        }
    }
    
    // UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.posts.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCellWithReuseIdentifier("userphotoCell", forIndexPath: indexPath) as! PostPicCollectionViewCell
        let post = self.posts[indexPath.item]
        cell.activityIV.startAnimating()
        cell.userInteractionEnabled = false
        cell.imageView!.kf_setImageWithURL(NSURL(string: post.imageUrl)!, placeholderImage: nil,
                                           optionsInfo: nil,
                                           progressBlock: { receivedSize, totalSize in
            },
                                           completionHandler: { image, error, cacheType, imageURL in
                                            post.image = image
                                            self.posts.append(post)
                                            if cell.activityIV.isAnimating() {
                                                cell.activityIV.stopAnimating()
                                            }
                                            cell.userInteractionEnabled = true
        })
        return cell
    }
    
    // UICollectionViewDelegate
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.selectedPost = self.posts[indexPath.item]
        self.performSegueWithIdentifier("post", sender: self)
    }
    
    // UICollectionViewDelegateFlowLayout
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        var itemSize: CGSize
        if self.width != nil {
            itemSize = CGSize(width: self.width!, height: self.width!)
        } else {
            itemSize = CGSizeZero
        }
        return itemSize
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func imageViewTapped(sender: AnyObject) {
        self.performSegueWithIdentifier("cvc", sender: self)
    }
    
    func willClose() {
    }
    
    func photoSelected(asset: PHAsset) {
        let manager = PHImageManager.defaultManager()
        let options = PHImageRequestOptions()
        options.resizeMode = PHImageRequestOptionsResizeMode.Exact
        options.deliveryMode = .FastFormat
        manager.requestImageForAsset(asset, targetSize: PHImageManagerMaximumSize, contentMode: .AspectFit, options: options) { (result, info) in
            self.profileImageView!.contentMode = .ScaleAspectFill
            self.profileImageView!.image = result
            self.profileImageView!.userInteractionEnabled = false
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                let imageRef = "profileImages/\(self.user!.uid).jpg"
                FirebaseClient.sharedInstance.uploadImage(result!, ref: imageRef) { success, url in
                    if success {
                        self.updateUserImage(url!)
                    }
                }
            }
        }
    }
    
    func updateUserImage(imageUrl: String) {
        let changeRequest = self.user!.profileChangeRequest()
        changeRequest.photoURL =
            NSURL(string: imageUrl)
        changeRequest.commitChangesWithCompletion { error in
            if error != nil {
                // An error happened.
            } else {
                if self.posts.count > 0 {
                    self.updateposts("userImage", newItem: imageUrl)
                }
            }
        }
    }
    
    func convertEnglishToJapanese(allergens: [String]) -> [String] {
        let userAllergiesToShow = allergens.map() { (item: String) -> String in
            var key = ""
            for (k, v) in Constants.allergens {
                if v == item {
                    key = k
                    break
                }
            }
            return key
        }
        return userAllergiesToShow
    }
    
    func nameLabelTapped(sender: UIGestureRecognizer){
        var oldName: String!
        oldName = self.nameLabel!.text!.stringByReplacingOccurrencesOfString("名前\n", withString: "")
        guard oldName != "ゲスト" else { return }
        let alertController = UIAlertController(title: "名前を編集", message: nil, preferredStyle: .Alert)
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.text = oldName
            textField.keyboardType = UIKeyboardType.Default
        }
        let cancelAction = UIAlertAction(title: "キャンセル", style: .Cancel) { (action) in
            alertController.dismissViewControllerAnimated(true, completion: nil)
        }
        alertController.addAction(cancelAction)
        let OKAction = UIAlertAction(title: "完了", style: .Default) { (action) in
            let textField = alertController.textFields![0]
            let newName = textField.text
            if newName != oldName {
                self.nameLabel!.text = "名前\n" + newName!
                let changeRequest = self.user!.profileChangeRequest()
                changeRequest.displayName = newName
                changeRequest.commitChangesWithCompletion { error in
                    if error != nil {
                        // An error happened.
                    } else {
                        if self.posts.count > 0 {
                            self.updateposts("user", newItem: newName!)
                        }
                    }
                }
                alertController.dismissViewControllerAnimated(true, completion: nil)
            }
        }
        alertController.addAction(OKAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func updateposts(itemToUpdate: String, newItem: String) {
        for post in self.posts {
            FirebaseClient.sharedInstance.postsRef.child("\(self.user!.uid)/\(post.id)").updateChildValues([itemToUpdate: newItem])
            FirebaseClient.sharedInstance.postsRef.child("\(post.resId)/\(post.id)").updateChildValues([itemToUpdate: newItem])
        }
    }
    
    func allergiesLabelTapped(sender: UIGestureRecognizer){
        let avc = self.storyboard?.instantiateViewControllerWithIdentifier("AllergiesViewController") as! AllergensViewController
        avc.delegate = self
        self.presentViewController(avc, animated: true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let pvc = segue.destinationViewController as? PostViewController {
            pvc.post = self.selectedPost
        }
        guard let navCon = segue.destinationViewController as? UINavigationController else { return }
        guard let cvc = navCon.visibleViewController as? CamerarollViewController else { return }
        if segue.identifier == "cvc" {
            cvc.delegate = self
            cvc.forProfilePic = true
            let allPhotosOptions = PHFetchOptions()
            allPhotosOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.Image.rawValue)
            allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            cvc.assetsFetchResults = PHAsset.fetchAssetsWithOptions(allPhotosOptions)
        }
    }
    
}

extension AccountViewController: AllergensViewControllerDelegate {
    func allergenChosen(allergens: [String]) {
        let userAllergiesToShow = self.convertEnglishToJapanese(allergens)
        allergiesLabel!.text = "アレルギー\n" + userAllergiesToShow.joinWithSeparator(", ")
    }
}


extension AccountViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text: String!
        if self.user != nil {
            text = "まだ写真を投稿していません。"
        } else {
            text = "現在ログインしていません。"
        }
        let attributes = [
            NSFontAttributeName: UIFont.boldSystemFontOfSize(18),
            NSForegroundColorAttributeName: UIColor.darkTextColor()
        ]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func verticalOffsetForEmptyDataSet(scrollView: UIScrollView!) -> CGFloat {
        return -self.profileView.frame.height / 2
    }
    
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text: String!
        if self.user != nil {
            text = "投稿した写真はこのページで見ることができます。"
        } else {
            text = "ログインすると投稿した写真がこのページで見ることができます。"
        }
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = NSTextAlignment.Left
        let attributes = [
            NSFontAttributeName: UIFont.boldSystemFontOfSize(14),
            NSForegroundColorAttributeName: UIColor.lightGrayColor(),
            NSParagraphStyleAttributeName: paragraph
        ]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func emptyDataSetShouldDisplay(scrollView: UIScrollView!) -> Bool {
        return self.emptyState
    }
}