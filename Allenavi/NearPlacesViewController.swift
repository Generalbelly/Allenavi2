//
//  NearPlacesViewController.swift
//  Allenavi
//
//  Created by ShimmenNobuyoshi on 2016/02/09.
//  Copyright © 2016年 ShimmenNobuyoshi. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps
import SVProgressHUD
import Alamofire
import SwiftyJSON
import MapKit
import GeoFire
import Firebase

protocol NPVCDelegate {
    func passTheAnswer(place: Place)
}

class NearPlacesViewController: UIViewController {
    var manager: CLLocationManager?
    var delegate: NPVCDelegate?
    var searchBar: UISearchBar!
    var chosenPlace: Place? {
        didSet {
            if chosenPlace != nil {
                self.delegate?.passTheAnswer(self.chosenPlace!)
            }
        }
    }
    var numberOfRestaurants = 0
    var localPlaces = [Place]() {
        didSet {
            if localPlaces.count > 0 && localPlaces.count == numberOfRestaurants {
                if SVProgressHUD.isVisible() {
                    SVProgressHUD.dismiss()
                }
                print(localPlaces.count)
                localPlaces.forEach() { place in
                    print(place.name)
                }
                self.tableView.reloadData()
            }
        }
    }
    var searchedPlaces = [Place]()
    var isFetching = false
    var locationBeingFetched = false {
        didSet {
            if !self.locationBeingFetched && GoogleMapsClientHelper.sharedInstance.currentLocation != nil {
                self.getNearbyRestaurantsFromDB(GoogleMapsClientHelper.sharedInstance.currentLocation!)
            }
        }
    }
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = UIColor.hex("EAEAEA", alpha: 1.0)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        SVProgressHUD.show()
        if GoogleMapsClientHelper.sharedInstance.currentLocation == nil {
            self.getCurrentLocation()
        } else {
            self.getNearbyRestaurantsFromDB(GoogleMapsClientHelper.sharedInstance.currentLocation!)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        createSearchBar()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.cleanUp()
    }
    
    func createSearchBar() {
        searchBar = UISearchBar(frame: CGRect(origin: CGPointZero, size: CGSize(width: self.view.frame.width, height: 44)))
        searchBar.userInteractionEnabled = false
        searchBar.placeholder = "現在地以外の場所から検索"
        let tappableView = UIView(frame: searchBar.frame)
        tappableView.userInteractionEnabled = true
        tappableView.backgroundColor = UIColor.clearColor()
        let tgr = UITapGestureRecognizer(target: self, action: #selector(NearPlacesViewController.barTapped(_:)))
        tappableView.addGestureRecognizer(tgr)
        searchBar.addSubview(tappableView)
        self.tableView.tableHeaderView = searchBar
        self.tableView.tableHeaderView?.userInteractionEnabled = true
        self.extendedLayoutIncludesOpaqueBars = true
        self.edgesForExtendedLayout = UIRectEdge.Top
        self.definesPresentationContext = true
    }
    
    func barTapped(sender: AnyObject) {
        let csvc = self.storyboard?.instantiateViewControllerWithIdentifier("CustomSearchVC") as! CustomSearchViewController
        csvc.fromForm = true
        csvc.delegate = self
        self.presentViewController(csvc, animated: true, completion: nil)
    }

    func cleanUp() {
        if self.manager != nil {
            self.manager = nil
        }
        if self.localPlaces.count > 0 {
            self.localPlaces.removeAll()
        }
        if SVProgressHUD.isVisible() {
            SVProgressHUD.dismiss()
        }
    }
}

extension NearPlacesViewController: CustomSearchViewControllerDelegate {
    func getSelectedPlace(place: Place) {
        if place.name == "現在地" {
            if !self.locationBeingFetched && GoogleMapsClientHelper.sharedInstance.currentLocation != nil {
                self.getNearbyRestaurantsFromDB(GoogleMapsClientHelper.sharedInstance.currentLocation!)
                self.searchBar.placeholder = "エリアから検索"
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
                    self.getNearbyRestaurantsFromDB(location!)
                    let placeName = "\(place.name)（\(place.address)）"
                    self.searchBar.placeholder = placeName
                }
            })
        }
    }
}

extension NearPlacesViewController: CLLocationManagerDelegate {
    
    func getCurrentLocation() {
        self.manager = CLLocationManager()
        GoogleMapsClientHelper.sharedInstance.checkAuthStatus(self, manager: self.manager!, locationBeingFetched: self.locationBeingFetched) { authorized in
            if authorized {
                self.startRequesting()
            }
        }
    }
    
    func startRequesting() {
        self.locationBeingFetched = true
        self.manager!.desiredAccuracy = kCLLocationAccuracyBest
        self.manager!.distanceFilter = 100
        self.manager!.startUpdatingLocation()
    }
    
    func getNearbyRestaurantsFromDB(center: CLLocation) {
        var counter = 0
        if !SVProgressHUD.isVisible() {
            SVProgressHUD.dismiss()
        }
        let circleQuery = FirebaseClient.sharedInstance.geoFire!.queryAtLocation(center, withRadius: 1)
        _ = circleQuery.observeEventType(GFEventType.KeyEntered, withBlock: { (key: String!, location: CLLocation!) in
            counter += 1
            self.isFetching = true
            FirebaseClient.sharedInstance.ref.child("restaurants").child(key).observeSingleEventOfType(.Value, withBlock: { snapshot in
                let place = Place()
                guard let item = snapshot.value as? [String: AnyObject] else { return }
                place.name = item["name"] as! String
                place.address = item["formattedAddress"] as! String
                place.dbId = item["id"] as! String
                self.localPlaces.append(place)
            })
        })
        circleQuery.observeReadyWithBlock() {
            if self.localPlaces.count == 0 && !self.isFetching {
                if SVProgressHUD.isVisible() {
                    SVProgressHUD.dismiss()
                }
                self.tableView.reloadData()
            } else {
                self.numberOfRestaurants = counter
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
            self.startRequesting()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if GoogleMapsClientHelper.sharedInstance.currentLocation == nil {
            GoogleMapsClientHelper.sharedInstance.currentLocation = manager.location!
            self.manager!.stopUpdatingLocation()
            self.locationBeingFetched = false
        }
    }
    
    func locationManager(manager: CLLocationManager,didFailWithError error: NSError){
    }
}

extension NearPlacesViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.localPlaces.count + 1
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        if indexPath.row == 0 {
            cell.textLabel?.text = "お店を新規登録"
            cell.detailTextLabel?.text = "検索しても見つからない場合は登録をお願いします。"
            cell.accessoryType = .DisclosureIndicator
        } else {
            let index = indexPath.row - 1
            let name =  self.localPlaces[index].name
            if self.chosenPlace != nil {
                if name == self.chosenPlace!.name {
                    cell.selected = true
                }
            }
            cell.textLabel?.text = name
            cell.detailTextLabel?.text = self.localPlaces[index].address
            if cell.selected {
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.None
            }
        }
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row != 0 {
            let cell = tableView.cellForRowAtIndexPath(indexPath) as UITableViewCell!
            if cell.accessoryType == UITableViewCellAccessoryType.None {
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
                self.chosenPlace = self.localPlaces[indexPath.row - 1]
            }
        } else {
            print("New place")
            self.performSegueWithIdentifier("register", sender: self)
        }
    }

    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row != 0 {
            let cell = tableView.cellForRowAtIndexPath(indexPath) as UITableViewCell!
            cell.accessoryType = UITableViewCellAccessoryType.None
        }
    }
}