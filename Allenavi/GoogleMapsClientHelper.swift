//
//  GoogleMapsClientHelper.swift
//  Allenavi
//
//  Created by ShimmenNobuyoshi on 2016/02/06.
//  Copyright © 2016年 ShimmenNobuyoshi. All rights reserved.
//

import Foundation
import GoogleMaps
import Alamofire
import SwiftyJSON

class GoogleMapsClientHelper {
    
    var placesClient: GMSPlacesClient?   
    static let sharedInstance = GoogleMapsClientHelper()
    var currentLocation: CLLocation?
    
    init() {
        self.placesClient =  GMSPlacesClient.sharedClient()
    }
    
    func placeAutocomplete(query: String, completionHandler: ([GMSAutocompletePrediction]? -> Void)) {
        var locationBounds: GMSCoordinateBounds?
        if GoogleMapsClientHelper.sharedInstance.currentLocation != nil {
            locationBounds = GoogleMapsClientHelper.sharedInstance.createBounds(GoogleMapsClientHelper.sharedInstance.currentLocation!, accuracy: 0.001)
        }
        placesClient?.autocompleteQuery(query, bounds: locationBounds, filter: nil, callback: { (results, error: NSError?) -> Void in
            if results != nil {
                completionHandler(results)
            } else {
                completionHandler(nil)
            }
        })
    }
    
    func getPlaceId(name: String, address: String, location: CLLocation, completionHandler: (String? -> Void)) {
        let param: [String: AnyObject] = ["location": "\(location.coordinate.latitude),\(location.coordinate.longitude)", "key": "AIzaSyBCOxBF_lOrMqqXRpixRoFJvqP9j0Rp-QI", "name": name, "keyword": address, "radius": "50", "types": "restaurant"]
        Alamofire.request(.GET, "https://maps.googleapis.com/maps/api/place/nearbysearch/json", parameters: param)
            .responseJSON { response in
                switch response.result {
                case .Success:
                    if let value = response.result.value {
                        let json = JSON(value)
                        let placeId = json["results"][0]["place_id"].stringValue
                        completionHandler(placeId)
                    }
                case .Failure( _):
                    completionHandler(nil)
                }
        }
    }
    
    func loadPhotosForPlace(placeId: String, completionHandler: ([UIImage] -> Void)) {
        GoogleMapsClientHelper.sharedInstance.placesClient?.lookUpPhotosForPlaceID(placeId) { (photos, error) -> Void in
            var remainingPhoto = 0
            var photosToReturn = [UIImage]()
            if error != nil {
                completionHandler(photosToReturn)
            } else if photos != nil {
                remainingPhoto = photos!.results.count
                if remainingPhoto > 0 {
                    for item in photos!.results {
                        GoogleMapsClientHelper.sharedInstance.loadImageForMetadata(item) { result in
                            remainingPhoto -= 1
                            let image = result["image"] as! UIImage
                            let attr = result["attributions"] as! String
                            if attr == "" {
                                photosToReturn.append(image)
                            }
                            if remainingPhoto == 0 {
                                completionHandler(photosToReturn)
                            }
                        }
                    }
                } else {
                    completionHandler(photosToReturn)
                }
            }
        }
    }
    
    func loadImageForMetadata(photoMetadata: GMSPlacePhotoMetadata, completionHandler: ([String: AnyObject] -> Void)) {
        GoogleMapsClientHelper.sharedInstance.placesClient?.loadPlacePhoto(photoMetadata) { (photo, error) -> Void in
                    if let error = error {
                        print("Error: \(error.description)")
                    } else if photo != nil {
                        let attr = photoMetadata.attributions?.string ?? ""
                        let result: [String: AnyObject] = ["image": photo!, "attributions": attr]
                        completionHandler(result)
                    }
        }
    }
    
    func getPlacesNearUser(completionHandler: ([Place] -> Void)) {
        var localPlaces = [Place]()
        GoogleMapsClientHelper.sharedInstance.placesClient?.currentPlaceWithCallback() { placeLikelihoods, error in
            guard error == nil else {
                return
            }
            if let placeLikelihoods = placeLikelihoods {
                for likelihood in placeLikelihoods.likelihoods {
                    let localPlace = likelihood.place
                    for type in localPlace.types {
                        if type == "restaurant" || type == "bakery" {
                            let place = Place()
                            place.placeId = localPlace.placeID
                            place.name = localPlace.name
                            place.lat = localPlace.coordinate.latitude
                            place.lon = localPlace.coordinate.longitude
                            place.phoneNumber = localPlace.phoneNumber
                            place.address = localPlace.formattedAddress ?? ""
                            place.attributions = localPlace.attributions?.string
                            localPlaces.append(place)
                            break
                        }
                    }
                }
            }
            completionHandler(localPlaces)
        }
    }
   
    func createBounds(location: CLLocation, accuracy: Double) -> GMSCoordinateBounds {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let center = CLLocationCoordinate2DMake(lat, lon)
        let northEast = CLLocationCoordinate2DMake(center.latitude + accuracy, center.longitude + accuracy)
        let southWest = CLLocationCoordinate2DMake(center.latitude - accuracy, center.longitude - accuracy)
        let bounds =  GMSCoordinateBounds(coordinate: northEast, coordinate: southWest)
        return bounds
    }

    
    func checkAuthStatus(vc: UIViewController, manager: CLLocationManager, locationBeingFetched: Bool, completionHandler: (Bool) -> Void) {
        guard locationBeingFetched == false else { return }
        switch CLLocationManager.authorizationStatus() {
        case .AuthorizedAlways:
            completionHandler(true)
        case .NotDetermined:
            manager.requestWhenInUseAuthorization()
            completionHandler(false)
        case .AuthorizedWhenInUse:
            completionHandler(true)
        case .Restricted, .Denied:
            let alertController = UIAlertController(
                title: "位置情報の取得ができません",
                message: "設定メニューよりアレナビの位置情報の利用を許可してください。",
                preferredStyle: .Alert)
            let cancelAction = UIAlertAction(title: "キャンセル", style: .Cancel, handler: nil)
            alertController.addAction(cancelAction)
            let openAction = UIAlertAction(title: "設定", style: .Default) { (action) in
                if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                    UIApplication.sharedApplication().openURL(url)
                }
            }
            alertController.addAction(openAction)
            vc.presentViewController(alertController, animated: true, completion: nil)
            completionHandler(false)
        }
    }

}