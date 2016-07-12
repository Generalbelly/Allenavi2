//
//  PicturesTableViewCell.swift
//  Allenavi
//
//  Created by ShimmenNobuyoshi on 2016/03/12.
//  Copyright © 2016年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit

class PicturesTableViewCell: UITableViewCell {

    @IBOutlet weak var collectionView: UICollectionView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setCollectionViewDataSourceDelegate
        <D: protocol<UICollectionViewDataSource, UICollectionViewDelegate>>
        (dataSourceDelegate: D, forRow row: Int) {
            collectionView.delegate = dataSourceDelegate
            collectionView.dataSource = dataSourceDelegate
            collectionView.reloadData()
    }
    
    var collectionViewOffset: CGFloat {
        get {
            return collectionView.contentOffset.x
        }
        set {
            collectionView.contentOffset.x = newValue
        }
    }

}
