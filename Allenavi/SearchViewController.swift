//
//  SearchViewController.swift
//  Allenavi
//
//  Created by ShimmenNobuyoshi on 2016/02/01.
//  Copyright © 2016年 ShimmenNobuyoshi. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps
import SVProgressHUD
import GeoFire
import Firebase
import Kingfisher
import DZNEmptyDataSet

class SearchViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var radius: UIBarButtonItem!
    @IBOutlet weak var slideBar: UISlider!
    @IBAction func radiusChanged(sender: UISlider) {
        let meter = Int(sender.value * 1000)
        self.radius.title = "\(meter)m"
        let value = Double(sender.value)
        if abs(lastTimeRadius - value) > 0.5 {
            self.getNearbyRestaurantsFromDB(self.lastTimeCenter!, fromCLLocation: self.lastTimefromCLLocation!, r: value)
        }
    }
    var emptyState = false
    var lastTimeSearchedPlace: String?
    var lastTimeRadius: Double = 0.5
    var lastTimeCenter: CLLocation?
    var lastTimefromCLLocation: Bool?
    let userDefaults = NSUserDefaults.standardUserDefaults()
    var numberOfRestaurants = 0
    var pickedRes: Place?
    var restaurants = [Place]() {
        didSet {
            if self.restaurants.count > 0 && self.restaurants.count == numberOfRestaurants {
                self.emptyState = false
                self.restaurants.sortInPlace() {(res1:Place, res2:Place) -> Bool in
                    res1.distance < res2.distance
                }
                self.lastTimeRadius = Double(slideBar.value)
                if SVProgressHUD.isVisible() {
                    SVProgressHUD.dismiss()
                }
                self.tableView.reloadData()
            }
        }
    }
    var manager: CLLocationManager? {
        didSet {
            if self.manager != nil {
                self.manager!.delegate = self
            }
        }
    }
    var locationBeingFetched = false {
        didSet {
            if !self.locationBeingFetched && GoogleMapsClientHelper.sharedInstance.currentLocation != nil {
                self.getNearbyRestaurantsFromDB(GoogleMapsClientHelper.sharedInstance.currentLocation!, fromCLLocation: true, r: lastTimeRadius)
            }
        }
    }
    @IBOutlet weak var filteringMessage: UILabel!
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            self.tableView.dataSource = self
            self.tableView.delegate = self
        }
    }
    @IBOutlet weak var searchBar: UISearchBar!
    @IBAction func searchBarTapped(sender: AnyObject) {
        self.performSegueWithIdentifier("search", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.slideBar.userInteractionEnabled = false
        self.tableView.emptyDataSetSource = self
        self.tableView.emptyDataSetDelegate = self
        self.tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        // NEW Allenavi UI
        self.navigationController?.navigationBar.tintColor = UIColor.hex("EAEAEA", alpha: 1.0)
        let image = UIImage()
        self.navigationController?.navigationBar.setBackgroundImage(image, forBarPosition: UIBarPosition.Any, barMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = image
        self.navigationController?.navigationBar.barTintColor = UIColor.hex("F69A4A", alpha: 1.0)
        self.navigationController?.navigationBar.backgroundColor = UIColor.hex("F69A4A", alpha: 1.0)
        
        if userDefaults.boolForKey("tosAsked") && userDefaults.boolForKey("allergiesAsked") {
            if GoogleMapsClientHelper.sharedInstance.currentLocation == nil {
                self.getCurrentLocation()
            }
            if let userAllergies = self.userDefaults.valueForKey("yourAllergies") as? [String] {
                if userAllergies.count > 0 {
                    let userAllergiesToShow = Constants.convertEnglishToJapanese(userAllergies)
                    self.filteringMessage.text =  userAllergiesToShow.joinWithSeparator(", ") + "を含まない料理を提供する店舗"
                } else {
                    self.filteringMessage.text = "アレルギー未選択"
                }
            }
        }
        self.createSearchBar()
    }
    
    func createSearchBar() {
        self.searchBar.placeholder = "取得中"
        if self.lastTimeSearchedPlace != nil {
            self.searchBar.placeholder = self.lastTimeSearchedPlace
        } else if GoogleMapsClientHelper.sharedInstance.currentLocation != nil {
            self.searchBar.placeholder = "現在地以外の場所から検索"
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if !userDefaults.boolForKey("tosAsked") {
            self.askTOS()
        } else if !userDefaults.boolForKey("allergiesAsked") {
            self.askAllergies()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.manager = nil
    }
    
    func askTOS() {
        let navCon = self.storyboard?.instantiateViewControllerWithIdentifier("tos") as! UINavigationController
        self.parentViewController!.presentViewController(navCon, animated:true, completion:nil)
    }
    
    func askAllergies() {
        let avc = self.storyboard!.instantiateViewControllerWithIdentifier("AllergiesViewController") as! AllergensViewController
        self.presentViewController(avc, animated: true, completion: nil)
    }

}

extension SearchViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let translation = self.tableView.panGestureRecognizer.translationInView(scrollView)
        if translation.y < 0 {
            self.hideBar(true, delayTime: 0.0)
        } else {
            self.hideBar(false, delayTime: 0.1)
        }
    }
    
    func hideBar(hide: Bool, delayTime: Double) {
        if self.navigationController?.navigationBarHidden == !hide {
            UIView.animateWithDuration(delayTime, animations: {
                self.navigationController?.navigationBarHidden = hide
            })
        }
    }
}

extension SearchViewController: CustomSearchViewControllerDelegate {
    func getSelectedPlace(place: Place) {
        if place.name == "現在地" {
            if !self.locationBeingFetched && GoogleMapsClientHelper.sharedInstance.currentLocation != nil {
                self.getNearbyRestaurantsFromDB(GoogleMapsClientHelper.sharedInstance.currentLocation!, fromCLLocation: true, r: lastTimeRadius)
                self.searchBar.placeholder = "現在地以外の場所から検索"
                self.lastTimeSearchedPlace = nil
            }
        } else {
            CLGeocoder().geocodeAddressString(place.address, completionHandler: { (placemarks, error) in
                if error != nil {
                    print(error)
                    return
                }
                guard placemarks != nil else { return }
                if placemarks!.count > 0 {
                    let placemark = placemarks![0]
                    let location = placemark.location
                    self.getNearbyRestaurantsFromDB(location!, fromCLLocation: false, r: self.lastTimeRadius)
                    let placeName = "\(place.name)（\(place.address)）"
                    self.searchBar.placeholder = placeName
                    self.lastTimeSearchedPlace = placeName
                }
            })
        }
    }
}

extension SearchViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "お店が見つかりませんでした。"
        let attributes = [
            NSFontAttributeName: UIFont.boldSystemFontOfSize(18),
            NSForegroundColorAttributeName: UIColor.darkTextColor()
        ]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "検索エリアを変更するか、スライダーを動かしてより広範囲を探してみてください。"
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

extension SearchViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.restaurants.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! SearchViewControllerCell
        if self.restaurants.count > 0 {
            let res = self.restaurants[indexPath.row]
            let name =  res.name
            if res.imageStrings != nil {
                let imageString = res.imageStrings!.first!
                cell.placeImageView.kf_showIndicatorWhenLoading = true
                cell.placeImageView.kf_setImageWithURL(NSURL(string: imageString)!, placeholderImage: nil,
                    optionsInfo: [.Transition(ImageTransition.Fade(1))],
                    progressBlock: { receivedSize, totalSize in
                    },
                    completionHandler: { image, error, cacheType, imageURL in
                })
            } else {
               cell.placeImageView.image = UIImage(named: "NoImage")
            }
            cell.distanceLabel.text = "徒歩\(res.distance / 50)分"
            cell.nameLabel.text = name
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.pickedRes = self.restaurants[indexPath.row]
        self.performSegueWithIdentifier("storeDetail", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let id = segue.identifier
        if id == "storeDetail" {
            let sdvc = segue.destinationViewController as? StoreDetailViewController
            sdvc!.place = self.pickedRes!
        } else if id == "search" {
            let csvc = segue.destinationViewController as? CustomSearchViewController
            csvc?.delegate = self
        }
    }
}

extension SearchViewController: CLLocationManagerDelegate {
    
    func getCurrentLocation() {
        self.manager = CLLocationManager()
        GoogleMapsClientHelper.sharedInstance.checkAuthStatus(self, manager: self.manager!, locationBeingFetched: self.locationBeingFetched) { authorized in
            if authorized {
                self.startRequesting()
            }
        }
    }
    
    func startRequesting() {
        SVProgressHUD.show()
        self.locationBeingFetched = true
        self.manager!.desiredAccuracy = kCLLocationAccuracyBest
        self.manager!.distanceFilter = 100
        self.manager!.startUpdatingLocation()
    }
    
    func getNearbyRestaurantsFromDB(center: CLLocation, fromCLLocation: Bool, r: Double) {
        var counter = 0
        self.restaurants.removeAll()
        if !SVProgressHUD.isVisible() {
            SVProgressHUD.show()
        }
        self.lastTimeCenter = center
        self.lastTimefromCLLocation = fromCLLocation
        let circleQuery = FirebaseClient.sharedInstance.geoFire!.queryAtLocation(center, withRadius: r)
        _ = circleQuery.observeEventType(GFEventType.KeyEntered, withBlock: { (key: String!, location: CLLocation!) in
            counter += 1
            FirebaseClient.sharedInstance.ref.child("restaurants/\(key)").observeSingleEventOfType(.Value, withBlock: { snapshot in
                guard let data = snapshot.value as? [String: AnyObject] else { return }
                let place = Place()
                if fromCLLocation {
                    place.distance = Int(GoogleMapsClientHelper.sharedInstance.currentLocation!.distanceFromLocation(location))
                } else {
                    place.distance = Int(center.distanceFromLocation(location))
                }
                place.lat = location.coordinate.latitude
                place.lon = location.coordinate.longitude
                place.name = data["name"] as! String
                place.phoneNumber = data["phone"] as? String
                place.address = data["formattedAddress"] as! String
                place.dbId = data["id"] as! String
                place.chainId = data["chainId"] as? String
                place.placeId = data["placeId"] as? String
                place.updatedAt = data["updatedAt"] as? String
                place.venueId = data["venueId"] as? String
                let fupdatedat = data["FSupdatedAt"] as? String
                self.checkFoursquare(fupdatedat, place: place, location: location) { checkedPlace in
                    self.restaurants.append(checkedPlace)
                }
            })
        })
        circleQuery.observeReadyWithBlock() {
            if counter == 0 {
                self.emptyState = true
                if SVProgressHUD.isVisible() {
                    SVProgressHUD.dismiss()
                }
                self.tableView.reloadData()
            } else {
                self.numberOfRestaurants = counter
            }
        }
    }
    
    func checkFoursquare(updatedDate: String?, place: Place, location: CLLocation, completionHandler: (Place -> Void)) {
        if place.venueId == nil {
            self.getVenueInfo(place, location: location) { returnedPlace in
                completionHandler(returnedPlace)
            }
        } else {
            if updatedDate != nil {
                let howOld = self.calculateTimeDiff(updatedDate!)
                if howOld >= 30 {
                    self.getVenueInfo(place, location: location) { returnedPlace in
                        completionHandler(returnedPlace)
                    }
                } else {
                    FoursquareClient.sharedInstance.getVenuePics(place.venueId!) { imageStrings in
                        if imageStrings.count > 0 {
                            place.imageStrings = imageStrings
                        }
                        completionHandler(place)
                    }
                }
            } else {
                print("do i need this?")
                self.getVenueInfo(place, location: location) { returnedPlace in
                    completionHandler(returnedPlace)
                }
            }
        }
    }

    func getVenueInfo(place: Place, location: CLLocation, completionHandler: (Place -> Void)) {
        FoursquareClient.sharedInstance.getVenueId(place.name, address: place.address, location: location) { data in
            if data.first != "" {
                 place.venueId = data.first!
            }
            guard place.venueId != nil else {
                completionHandler(place)
                return
            }
            FirebaseClient.sharedInstance.ref.child("restaurants/\(place.dbId)").updateChildValues(["venueId": place.venueId!, "FSupdatedAt": FirebaseClient.sharedInstance.timestamp])
            if place.phoneNumber == nil && data.last != "" {
                place.phoneNumber = data.last!
                FirebaseClient.sharedInstance.ref.child("restaurants/\(place.dbId)").updateChildValues(["phone": place.phoneNumber!])
            }
            FoursquareClient.sharedInstance.getVenuePics(place.venueId!) { imageStrings in
                if imageStrings.count > 0 {
                    place.imageStrings = imageStrings
                }
                completionHandler(place)
            }
        }
    }
    
    func calculateTimeDiff(updatedDateString: String) -> Int {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd 'at' HH:mm"
        let updatedDate = dateFormatter.dateFromString(updatedDateString)
        let currentDateString = dateFormatter.stringFromDate(NSDate())
        let currentDate = dateFormatter.dateFromString(currentDateString)
        let diffDateComponents = NSCalendar.currentCalendar().components([NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second], fromDate: updatedDate!, toDate: currentDate!, options: NSCalendarOptions.init(rawValue: 0))
        return diffDateComponents.day
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
            self.startRequesting()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if GoogleMapsClientHelper.sharedInstance.currentLocation == nil {
            GoogleMapsClientHelper.sharedInstance.currentLocation = manager.location!
            self.searchBar.placeholder = "現在地以外の場所から検索"
            self.manager!.stopUpdatingLocation()
            self.locationBeingFetched = false
            self.slideBar.userInteractionEnabled = true
        }
    }
    
    func locationManager(manager: CLLocationManager,didFailWithError error: NSError){
    }

}