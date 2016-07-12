//
//  TOSViewController.swift
//  Allenavi
//
//  Created by ShimmenNobuyoshi on 2016/04/07.
//  Copyright © 2016年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit
import Foundation
import SVProgressHUD

class TOSViewController: UIViewController {

    @IBAction func agreeTapped(sender: AnyObject) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if (userDefaults.valueForKey("tosAsked") == nil) {
            userDefaults.setBool(true, forKey: "tosAsked")
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated:true)
        self.navigationController?.navigationBar.backgroundColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.translucent = false
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        SVProgressHUD.show()
        let dvc = segue.destinationViewController as? DetailViewController
        dvc?.pageUrl = "http://unbouncepages.com/good-bank-714/"
    }

}
