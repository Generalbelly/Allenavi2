//
//  Place.swift
//  Allenavi
//
//  Created by ShimmenNobuyoshi on 2016/02/05.
//  Copyright © 2016年 ShimmenNobuyoshi. All rights reserved.
//

import Foundation

class Place {
    var new = false
    var placeId: String?
    var venueId: String?
    var name = ""
    var address = ""
    var lat: Double = 0
    var lon: Double = 0
    var attributions: String?
    var phoneNumber: String?
    var dbId = ""
    var chainId: String?
    var imageStrings: [String]?
    var distance = 0
    var updatedAt: String?
}
