//
//  CustomBarViewController.swift
//  Allenavi
//
//  Created by ShimmenNobuyoshi on 2016/01/23.
//  Copyright © 2016年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit
import PhotosUI
import Firebase

class CustomBarViewController: UITabBarController, UITabBarControllerDelegate, CamerarollViewDelegate {

    var button: UIButton = UIButton()
    var isHighLighted:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        let middleImage = UIImage(named:"Camera")!
        let highlightedMiddleImage = UIImage(named:"BGCamera")
        addCenterButtonWithImage(middleImage, highlightImage: highlightedMiddleImage)
        self.tabBar.barTintColor = UIColor.blackColor()
    }
    
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        if !viewController.isKindOfClass(CamerarollViewController) {
            button.userInteractionEnabled = true
            button.highlighted = false
            button.selected = false
            isHighLighted = false
        } else {
            button.userInteractionEnabled = false
        }
    }

    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        if  self.selectedViewController == viewController {
            return false
        }
        return true
    }


    func addCenterButtonWithImage(buttonImage: UIImage, highlightImage:UIImage?) {
        let tabBarSize = self.tabBar.frame.size
        let frame = CGRectMake(0.0, 0.0, tabBarSize.width / 3, tabBarSize.height)
        button = UIButton(frame: frame)
        button.backgroundColor = UIColor.clearColor()
        button.setImage(buttonImage, forState: .Normal)
        button.setImage(highlightImage, forState: .Highlighted)
        let heightDifference:CGFloat = buttonImage.size.height - self.tabBar.frame.size.height
        if heightDifference < 0 {
            button.center = CGPointMake(self.tabBar.center.x, self.tabBar.center.y)
        } else {
            var center:CGPoint = self.tabBar.center
            center.y = center.y - heightDifference/2.0
            button.center = center
        }
        button.addTarget(self, action: #selector(CustomBarViewController.changeTabToMiddleTab(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(button)
    }
    
    func changeTabToMiddleTab(sender:UIButton) {
        if FIRAuth.auth()?.currentUser == nil {
            self.performSegueWithIdentifier("login", sender: self)
        } else {
            self.performSegueWithIdentifier("camerarollView", sender: self)
            dispatch_async(dispatch_get_main_queue()) {
                if self.isHighLighted == false {
                    sender.highlighted = true
                    self.isHighLighted = true
                } else {
                    sender.highlighted = false
                    self.isHighLighted = false
                }
            }
            sender.userInteractionEnabled = false
        }
    }
    
    func willClose() {
        self.button.highlighted = false
        self.isHighLighted = false
        self.button.userInteractionEnabled = true
    }
    
    func photoSelected(asset: PHAsset) {
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let navCon = segue.destinationViewController as? UINavigationController else { return }
        guard let cvc = navCon.visibleViewController as? CamerarollViewController else { return }
        if segue.identifier == "camerarollView" {
            cvc.delegate = self
        }
    }
}
