//
//  PostViewController.swift
//  Allenavi
//
//  Created by ShimmenNobuyoshi on 2016/03/30.
//  Copyright © 2016年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit
import JTSImageViewController

class PostViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    var imageView: UIImageView! {
        didSet {
            self.imageView.contentMode = UIViewContentMode.ScaleAspectFill
            self.imageView.clipsToBounds = true
            self.imageView.userInteractionEnabled = true
            let tgr = UITapGestureRecognizer(target: self, action: #selector(PostViewController.picTapped(_:)))
            self.imageView.addGestureRecognizer(tgr)
        }
    }
    var button: UIButton!
    var post: Post? {
        didSet {
            if post != nil {
                self.imageView = UIImageView(frame: CGRectMake(0, 0, self.view.bounds.width, self.view.bounds.width))
                self.imageView.image = post!.image
                self.tableView.tableHeaderView = self.imageView
                self.tableView.separatorColor = UIColor.clearColor()
                self.tableView.tableFooterView = UIView()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.tintColor = UIColor.hex("EAEAEA", alpha: 1.0)
    }
    
    func picTapped(recognizer: UIGestureRecognizer) {
        let postPic = recognizer.view as? UIImageView
        let imageInfo = JTSImageInfo()
        imageInfo.image = postPic!.image
        let imageViewer = JTSImageViewController(imageInfo: imageInfo, mode: JTSImageViewControllerMode.Image, backgroundStyle: JTSImageViewControllerBackgroundOptions.Blurred)
        imageViewer.showFromViewController(self, transition: JTSImageViewControllerTransition.FromOffscreen)
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "コメント"
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        var commentToShow: String?
        if self.post!.comment == "" {
            commentToShow = "なし"
        } else {
            commentToShow = self.post!.comment
        }
        cell.textLabel!.text = commentToShow
        cell.textLabel!.sizeToFit()
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
}
