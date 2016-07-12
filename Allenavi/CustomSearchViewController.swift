//
//  CustomSearchViewController.swift
//  Allenavi
//
//  Created by ShimmenNobuyoshi on 2016/04/29.
//  Copyright © 2016年 ShimmenNobuyoshi. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps

protocol CustomSearchViewControllerDelegate {
    func getSelectedPlace(address: Place)
}

class CustomSearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    var delegate: CustomSearchViewControllerDelegate?
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            self.tableView.delegate = self
            self.tableView.dataSource = self
        }
    }
    var fromForm = false
    var searchController = UISearchController(searchResultsController: nil)
    var results = [Place]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addCurrentPlace()
        self.addLogo()
        self.navigationController?.navigationBarHidden = true
        UIApplication.sharedApplication().statusBarHidden = true
    }
    
    override func viewWillAppear(animated: Bool) {
        self.createSearchBar()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.searchController.active = true
        dispatch_async(dispatch_get_main_queue()) {
            self.searchController.searchBar.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.searchController.searchBar.resignFirstResponder()
        self.searchController.active = false
        UIApplication.sharedApplication().statusBarHidden = false
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    func createSearchBar() {
        self.searchController.searchResultsUpdater = self
        self.searchController.searchBar.delegate = self
        self.searchController.searchBar.placeholder = "エリア名を入力してください"
        self.searchController.hidesNavigationBarDuringPresentation = true
        self.extendedLayoutIncludesOpaqueBars = true
        self.edgesForExtendedLayout = UIRectEdge.Top
        self.definesPresentationContext = true
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.searchBar.showsCancelButton = true
        self.tableView.tableHeaderView = self.searchController.searchBar
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.results.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let place = results[indexPath.row]
        if place.name == "logo" {
            let cell = tableView.dequeueReusableCellWithIdentifier("logo", forIndexPath: indexPath)
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
            cell.textLabel!.text = place.name
            cell.detailTextLabel!.text = place.address
            return cell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let place = self.results[indexPath.row]
        self.delegate?.getSelectedPlace(place)
        if !self.searchController.isBeingDismissed() {
            self.searchController.dismissViewControllerAnimated(true, completion: nil)
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func addCurrentPlace() {
        let currentPlace = Place()
        currentPlace.name = "現在地"
        self.results.append(currentPlace)
    }
    
    func addLogo() {
        let logo = Place()
        logo.name = "logo"
        self.results.append(logo)
    }
}

extension CustomSearchViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        GoogleMapsClientHelper.sharedInstance.placeAutocomplete(searchController.searchBar.text!) { results in
            if results != nil {
                self.results.removeAll()
                self.addCurrentPlace()
                for result in results! {
                    let place = Place()
                    place.name = result.attributedPrimaryText.string
                    place.address = result.attributedSecondaryText?.string ?? ""
                    self.results.append(place)
                }
                self.addLogo()
                self.tableView.reloadData()
            }
        }
    }
}