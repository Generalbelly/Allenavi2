//
//  UserPostViewCellTableViewCell.swift
//  Allenavi
//
//  Created by ShimmenNobuyoshi on 2016/05/19.
//  Copyright © 2016年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit

class UserPostViewCell: UITableViewCell {

    @IBOutlet weak var userImage: UIImageView! {
        didSet {
            
        }
    }
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userAllergies: UILabel!
    @IBOutlet weak var postPic: UIImageView!
    @IBOutlet weak var comment: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
