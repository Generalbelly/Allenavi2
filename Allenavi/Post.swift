//
//  Post.swift
//  Allenavi
//
//  Created by ShimmenNobuyoshi on 2016/03/26.
//  Copyright © 2016年 ShimmenNobuyoshi. All rights reserved.
//

import Foundation
import Kingfisher

class Post {
    var id = ""
    var userId = ""
    var image: UIImage?
    var imageUrl = ""
    var createdAt = ""
    var comment = ""
    var user = ""
    var allergies = [String]()
    var userImage = ""
    var resId = ""
}

class ImageHandlingHelper {
    static let sharedInstance = ImageHandlingHelper()
    func getImage(id: String, imageString: String, completionHandler: UIImage -> Void) {
        let optionsInfos: KingfisherOptionsInfo = [
            .CacheMemoryOnly,
            .ForceRefresh,
            .Transition(ImageTransition.Fade(1))
        ]
        KingfisherManager.sharedManager.cache.retrieveImageForKey(id, options: optionsInfos) { cachedImage, type in
            if cachedImage != nil {
                completionHandler(cachedImage!)
            } else {
                let data = NSData(base64EncodedString: imageString, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
                let image = UIImage(data: data!)!
                KingfisherManager.sharedManager.cache.storeImage(image, originalData: data, forKey: id, toDisk: false, completionHandler: nil)
                completionHandler(image)
            }
        }
    }
}