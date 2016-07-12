//
//  SearchViewControllerCell.swift
//  Allenavi
//
//  Created by ShimmenNobuyoshi on 2016/02/09.
//  Copyright © 2016年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit
import Kingfisher

class SearchViewControllerCell: UITableViewCell {
    
    @IBOutlet weak var placeImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var overlayView: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
