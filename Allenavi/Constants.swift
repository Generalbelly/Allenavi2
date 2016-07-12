//
//  Constants.swift
//  Allenavi
//
//  Created by ShimmenNobuyoshi on 2016/03/25.
//  Copyright © 2016年 ShimmenNobuyoshi. All rights reserved.
//

import Foundation

struct Constants {
    static let allergens = ["卵": "egg", "乳": "milk"]
    static let keys = ["卵", "乳"]
    
    static func convertEnglishToJapanese(allergens: [String]) -> [String] {
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
}