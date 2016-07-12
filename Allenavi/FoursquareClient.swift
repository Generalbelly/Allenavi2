//
//  FoursquareClient.swift
//  Allenavi
//
//  Created by ShimmenNobuyoshi on 2016/03/07.
//  Copyright © 2016年 ShimmenNobuyoshi. All rights reserved.
//

import Foundation
import CoreLocation
import Alamofire
import SwiftyJSON

class FoursquareClient {
    static let sharedInstance = FoursquareClient()
    func getVenueId(name: String, address: String, location: CLLocation, completionHandler: ([String] -> Void)) {
        let param: [String: AnyObject] = [Keys.SECRET: Constants.API_SECRET, Keys.ID: Constants.API_ID, Keys.VERSION: Constants.VDATE, "ll": "\(location.coordinate.latitude),\(location.coordinate.longitude)", "query": name, "address": address, "intent": "match"]
        Alamofire.request(.GET, "https://api.foursquare.com/v2/venues/search", parameters: param)
            .responseJSON { response in
                switch response.result {
                case .Success:
                    if let value = response.result.value {
                        let json = JSON(value)
                        let item = json["response"]["venues"][0]
                        let venueId = item["id"].string ?? ""
                        let phone = item["contact"]["formattedPhone"].string ?? ""
                        completionHandler([venueId, phone])
                    }
                case .Failure( _):
                    completionHandler([""])
                }
        }
    }
    
    func getVenuePics(venueId: String, completionHandler: ([String] -> Void)) {
        var imageString = [String]()
        let param: [String: AnyObject] = [Keys.SECRET: Constants.API_SECRET, Keys.ID: Constants.API_ID, Keys.VERSION: Constants.VDATE]
        Alamofire.request(.GET, "https://api.foursquare.com/v2/venues/\(venueId)/photos", parameters: param)
        .responseJSON { response in
            switch response.result {
            case .Success:
                if let value = response.result.value {
                    let json = JSON(value)
                    let itemCount = json["response"]["photos"]["count"].intValue
                    if itemCount > 0 {
                        for i in 0...(itemCount - 1) {
                            let item = json["response"]["photos"]["items"][i]
                            let prefix = item["prefix"].stringValue
                            let suffix = item["suffix"].stringValue
                            let concatinated = prefix + "original" + suffix
                            imageString.append(concatinated)
                        }
                    }
                    completionHandler(imageString)
                }
            case .Failure( _):
                completionHandler(imageString)
            }
        }
    }
    
    struct Constants {
        static let API_SECRET = "053C2P3SRV4D2LZGCXX021OUHXYZY42HZDBARMVJVYAA5ISD"
        static let API_ID = "DWDIIU5MXLD4QTLRNMZLIMDGSD205U2QPTQZ1S5TJ5GJBL1V"
        static let VDATE = "20160306"
    }
    
    struct Keys {
        static let SECRET = "client_secret"
        static let ID = "client_id"
        static let VERSION = "v"
    }
}