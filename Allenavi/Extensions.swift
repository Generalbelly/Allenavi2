//
//  Extensions.swift
//  Allenavi
//
//  Created by ShimmenNobuyoshi on 2016/01/23.
//  Copyright © 2016年 ShimmenNobuyoshi. All rights reserved.
//

import Foundation
import UIKit

extension UICollectionView {
    func indexPathsForElementsInRect(rect: CGRect) -> NSArray? {
        let allLayoutAttributes = self.collectionViewLayout.layoutAttributesForElementsInRect(rect)!
        if allLayoutAttributes.count == 0 { return nil }
        let indexPaths = NSMutableArray(capacity: allLayoutAttributes.count)
        for item in allLayoutAttributes {
            let indexPath = item.indexPath
            indexPaths.addObject(indexPath)
        }
        return indexPaths
    }
}

extension NSIndexSet {
    func indexPathsFromIndexesWithSection(section: Int) -> NSArray {
        let indexPaths = NSMutableArray(capacity: self.count)
        self.enumerateIndexesUsingBlock(){ id, stop in
            indexPaths.addObject(NSIndexPath(forItem: id, inSection: section))
        }
        return indexPaths
    }
}

extension String {
    func stringByAppendingPathComponent(path: String) -> String {
        let nsSt = self as NSString
        return nsSt.stringByAppendingPathComponent(path)
    }
}

extension UIColor {
    class func hex (hexStr : NSString, alpha : CGFloat) -> UIColor {
        let hexStr = hexStr.stringByReplacingOccurrencesOfString("#", withString: "")
        let scanner = NSScanner(string: hexStr as String)
        var color: UInt32 = 0
        if scanner.scanHexInt(&color) {
            let r = CGFloat((color & 0xFF0000) >> 16) / 255.0
            let g = CGFloat((color & 0x00FF00) >> 8) / 255.0
            let b = CGFloat(color & 0x0000FF) / 255.0
            return UIColor(red:r,green:g,blue:b,alpha:alpha)
        } else {
            return UIColor.whiteColor()
        }
    }
}

extension String {
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluateWithObject(self)
    }
}

extension UIImage {
    var uncompressedPNGData: NSData      { return UIImagePNGRepresentation(self)!        }
    var highestQualityJPEGNSData: NSData { return UIImageJPEGRepresentation(self, 1.0)!  }
    var highQualityJPEGNSData: NSData    { return UIImageJPEGRepresentation(self, 0.75)! }
    var mediumQualityJPEGNSData: NSData  { return UIImageJPEGRepresentation(self, 0.5)!  }
    var lowQualityJPEGNSData: NSData     { return UIImageJPEGRepresentation(self, 0.25)! }
    var lowestQualityJPEGNSData:NSData   { return UIImageJPEGRepresentation(self, 0.0)!  }
}

