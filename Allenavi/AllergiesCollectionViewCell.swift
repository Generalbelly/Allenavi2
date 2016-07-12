//
//  AllergiesTableViewCell.swift
//  Allenavi
//
//  Created by ShimmenNobuyoshi on 2016/03/18.
//  Copyright © 2016年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit

class AllergiesCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var allergyName: UILabel!
    @IBOutlet weak var allergyNameWithImage: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
}
