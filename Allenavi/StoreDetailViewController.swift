//
//  StoreDetailViewController.swift
//  Allenavi
//
//  Created by ShimmenNobuyoshi on 2016/02/01.
//  Copyright © 2016年 ShimmenNobuyoshi. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import Firebase
import SVProgressHUD
import Kingfisher
import JTSImageViewController

class StoreDetailViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    var posts: [Post]? {
        didSet {
            if posts != nil {
                self.tableView.estimatedRowHeight = self.view.bounds.width * 1.3
                self.tableView.reloadData()
            }
        }
    }
    let nameRow = 0
    let addressRow = 1
    let phoneRow = 2
    let pictureRow = 3
    var formattedPhone: String?
    var cache: ImageCache?
    var storedOffsets = [Int: CGFloat]()
    var place: Place? {
        didSet {
            if place != nil {
                FirebaseClient.sharedInstance.postsRef.child(place!.dbId).observeSingleEventOfType(.Value, withBlock: { snapshot in
                    if snapshot.exists() {
                        var fetchedPosts = [Post]()
                        for item in snapshot.children.allObjects as! [FIRDataSnapshot] {
                            let value = item.value as! [String: AnyObject]
                            let post = FirebaseClient.sharedInstance.createPost(value)
                            fetchedPosts.append(post)
                        }
                        self.posts = fetchedPosts
                    }
                })
            }
        }
    }
    var mapView = MKMapView()
    var location: MKPlacemark?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.cache = KingfisherManager.sharedManager.cache
        self.createMapView()
        if self.navigationController?.navigationBarHidden == true {
            self.navigationController?.navigationBarHidden = false
        }
    }
    
    func createMapView() {
        self.mapView.frame = CGRectMake(0, 0, self.view.bounds.width, 200)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.tableHeaderView = self.mapView
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2DMake(place!.lat, place!.lon), addressDictionary: nil)
        self.mapView.addAnnotation(placemark)
        self.mapView.showAnnotations([placemark], animated: true)
    }
    
    func createImageViews(cell: UICollectionViewCell, index: Int) {
        let length: CGFloat = cell.bounds.height
        let imageView = UIImageView(frame: CGRectMake(0, 0, length, length))
        imageView.contentMode = .ScaleAspectFill
        imageView.kf_setImageWithURL(NSURL(string: self.place!.imageStrings![index])!, placeholderImage: nil,
                                     optionsInfo: [.Transition(ImageTransition.Fade(1))],
                                     progressBlock: { receivedSize, totalSize in
            },
                                     completionHandler: { image, error, cacheType, imageURL in
        })
        let tgr = UITapGestureRecognizer(target: self, action: #selector(StoreDetailViewController.pictureTapped(_:)))
        imageView.addGestureRecognizer(tgr)
        imageView.tag = index
        imageView.userInteractionEnabled = true
        cell.contentView.addSubview(imageView)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.location = nil
    }
    
    func pictureTapped(sender: UIGestureRecognizer) {
        let pic = sender.view as! UIImageView
        let imageInfo = JTSImageInfo()
        imageInfo.image = pic.image
        let imageViewer = JTSImageViewController(imageInfo: imageInfo, mode: JTSImageViewControllerMode.Image, backgroundStyle: JTSImageViewControllerBackgroundOptions.Blurred)
        imageViewer.showFromViewController(self, transition: JTSImageViewControllerTransition.FromOffscreen)
    }
    
}

extension StoreDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if self.place!.imageStrings != nil {
                return 4
            } else {
                return 3
            }
        } else {
            return posts!.count
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if posts != nil {
            return 2
        } else {
            return 1
        }
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        guard let tableViewCell = cell as? PicturesTableViewCell else { return }
        tableViewCell.setCollectionViewDataSourceDelegate(self, forRow: indexPath.row)
        tableViewCell.collectionViewOffset = storedOffsets[indexPath.row] ?? 0
    }
    
    func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        guard let tableViewCell = cell as? PicturesTableViewCell else { return }
        self.storedOffsets[indexPath.row] = tableViewCell.collectionViewOffset
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        var height: CGFloat = 0
        if indexPath.section != 0 {
            height = UITableViewAutomaticDimension
        } else if indexPath.row == self.pictureRow {
            height = 120
        } else {
            height = 44
        }
        return height
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            var cell: UITableViewCell!
            if indexPath.row == self.pictureRow {
                cell = self.tableView.dequeueReusableCellWithIdentifier("picsCell")!
            } else {
                cell = self.tableView.dequeueReusableCellWithIdentifier("cell")!
                let label = cell.textLabel!
                let detailLabel = cell.detailTextLabel!
                switch indexPath.row {
                case self.nameRow:
                    label.text = "店名"
                    detailLabel.text = self.place!.name
                    cell.userInteractionEnabled = false
                case self.addressRow:
                    label.text = "住所"
                    detailLabel.text = self.place!.address
                case self.phoneRow:
                    label.text = "電話"
                    let phone = self.place!.phoneNumber ?? "情報なし"
                    if phone == "情報なし" {
                        cell.userInteractionEnabled = false
                        detailLabel.text = phone
                    } else {
                        self.formattedPhone = phone.stringByReplacingOccurrencesOfString("+81 ", withString: "0")
                        detailLabel.text = self.formattedPhone
                    }
                default:
                    break
                }
            }
            return cell
        } else {
            let cell = self.tableView.dequeueReusableCellWithIdentifier("postCell") as! UserPostViewCell
            let post = self.posts![indexPath.row]
            var username = "匿名ユーザー"
            if post.user != "" {
                username = post.user
            }
            cell.userName.text = username
            cell.userAllergies.text = Constants.convertEnglishToJapanese(post.allergies).joinWithSeparator(", ")
            cell.comment.text = post.comment
            if post.userImage != "" {
                cell.userImage!.kf_setImageWithURL(NSURL(string: post.userImage)!, placeholderImage: nil, optionsInfo: nil, progressBlock: { receivedSize, totalSize in }, completionHandler: { image, error, cacheType, imageURL in
                        if image!.size.height > image!.size.width {
                            cell.userImage.contentMode = .ScaleAspectFill
                        }
                })
            } else {
                cell.userImage.image = UIImage(named: "NoImage")
            }
            cell.userImage.layer.cornerRadius = cell.userImage.bounds.height / 2
            cell.userImage.layer.masksToBounds = true
            cell.postPic!.kf_setImageWithURL(NSURL(string: post.imageUrl)!, placeholderImage: nil, optionsInfo: nil, progressBlock: { receivedSize, totalSize in }, completionHandler: { image, error, cacheType, imageURL in
                if image!.size.height > image!.size.width {
                    cell.postPic!.contentMode = .ScaleAspectFill
                }
                cell.postPic.userInteractionEnabled = true
                let tgr = UITapGestureRecognizer(target: self, action: #selector(StoreDetailViewController.picTapped(_:)))
                cell.postPic.addGestureRecognizer(tgr)
            })
            return cell
        }
    }
    
    func picTapped(recognizer: UIGestureRecognizer) {
        let postPic = recognizer.view as? UIImageView
        let imageInfo = JTSImageInfo()
        imageInfo.image = postPic!.image
        let imageViewer = JTSImageViewController(imageInfo: imageInfo, mode: JTSImageViewControllerMode.Image, backgroundStyle: JTSImageViewControllerBackgroundOptions.Blurred)
        imageViewer.showFromViewController(self, transition: JTSImageViewControllerTransition.FromOffscreen)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.row {
        case self.addressRow:
            self.openMapapp()
        case self.phoneRow:
            self.callNumber(self.formattedPhone!)
        default:
            break
        }
    }
    
    func callNumber(number: String) {
        let number = formattedPhone!.stringByReplacingOccurrencesOfString("-", withString: "")
        if let phoneCallURL:NSURL = NSURL(string: "tel://\(number)") {
            let application:UIApplication = UIApplication.sharedApplication()
            if (application.canOpenURL(phoneCallURL)) {
                application.openURL(phoneCallURL)
            }
        }
    }
    
    func openMapapp() {
        let encodedAddress = place!.address.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLFragmentAllowedCharacterSet())!
        if (UIApplication.sharedApplication().canOpenURL(NSURL(string:"comgooglemaps://")!)) {
            self.userpickMapApp(encodedAddress, googleMap: true)
        } else {
            self.userpickMapApp(encodedAddress, googleMap: false)
        }
    }
    
    func userpickMapApp(encodedAddress: String, googleMap: Bool){
        let alertController = UIAlertController(title: "お店までの道のりを表示", message: "地図アプリをお選びください", preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "キャンセル", style: .Cancel) { _ in
            alertController.dismissViewControllerAnimated(true, completion: nil)
        }
        if googleMap {
            let googleAction = UIAlertAction(title: "Google Mapsで開く", style: .Default) { _ in
                UIApplication.sharedApplication().openURL(NSURL(string: "comgooglemaps://?daddr=\(encodedAddress)")!)
                alertController.dismissViewControllerAnimated(true, completion: nil)
            }
            alertController.addAction(googleAction)
        }
        let appleAction = UIAlertAction(title: "マップで開く", style: .Default) { _ in
            let url = NSURL(string: "http://maps.apple.com/?daddr=\(encodedAddress)")
            UIApplication.sharedApplication().openURL(url!)
            alertController.dismissViewControllerAnimated(true, completion: nil)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(appleAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
}

extension StoreDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return self.place!.imageStrings?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell",
                                                                         forIndexPath: indexPath)
        self.createImageViews(cell, index: indexPath.row)
        return cell
    }
}