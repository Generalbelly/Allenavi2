//
//  PlainTalbeViewController.swift
//  Allenavi
//
//  Created by ShimmenNobuyoshi on 2016/02/06.
//  Copyright © 2016年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit

protocol PTVCDelegate {
    func passTheAnswers(answers: [String])
}

class PlainTalbeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var delegate: PTVCDelegate?
    var chosenAllergies = [String]() {
        didSet {
            if chosenAllergies.count > 0 {
                self.delegate?.passTheAnswers(chosenAllergies)
            }
        }
    }
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        let userDefaults = NSUserDefaults()
        if let userAllergies = userDefaults.valueForKey("yourAllergies") as? [String] {
            self.chosenAllergies = userAllergies.map() { item -> String in
                var key = ""
                for (k, v) in Constants.allergens {
                    if v == item {
                        key = k
                        break
                    }
                }
                return key
            }
        }
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.allowsMultipleSelection = true
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Constants.allergens.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        let allergy = Constants.keys[indexPath.row]
        for item in self.chosenAllergies {
            if item == allergy {
                cell.selected = true
                tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .None)
                break
            }
        }
        cell.textLabel?.text = allergy
        if self.chosenAllergies.contains(allergy) {
            cell.selected = true
        }
        if cell.selected {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.None
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as UITableViewCell!
        if cell.accessoryType == UITableViewCellAccessoryType.None {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            self.chosenAllergies.append(Constants.keys[indexPath.row])
        }
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as UITableViewCell!
        cell.accessoryType = UITableViewCellAccessoryType.None
        for (index, allergy) in self.chosenAllergies.enumerate() {
            if allergy == Constants.keys[indexPath.row] {
                self.chosenAllergies.removeAtIndex(index)
                break
            }
        }
    }
//
//    let cell = collectionView.cellForItemAtIndexPath(indexPath) as! AllergiesCollectionViewCell
//    self.changeCellColor(cell, selected: false)
//    let allergy = self.keys[indexPath.item]
//    for (index, item) in self.selectedAllergies.enumerate() {
//    if allergy.isEqual(item) {
//    self.selectedAllergies.removeAtIndex(index)
//    }
//    }
    
}
