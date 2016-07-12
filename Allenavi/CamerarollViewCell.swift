//
//  CamerarollCell.swift
//  Allenavi
//
//  Created by ShimmenNobuyoshi on 2016/01/23.
//  Copyright © 2016年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit

class CamerarollViewCell: UICollectionViewCell {
    var thumbnailImage = UIImage() {
        didSet {
            self.imageView.image = thumbnailImage
        }
    }
    @IBOutlet weak var selectedView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    var representedAssetIdentifier: String = ""
    
}
