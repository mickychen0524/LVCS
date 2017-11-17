//
//  StoreLocatorViewController.swift
//  CountryFair
//
//  Created by Micky on 8/18/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import GoogleMaps
import Alamofire

class StoreLocatorViewController: UIViewController {
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var displayModeButton: UIButton!
    @IBOutlet weak var storeTableView: UITableView!
    @IBOutlet weak var backButton: UIButton!
    
    var mapView: GMSMapView!
    
    var latitude: Double! = 33.7490
    var longitude: Double! = 84.3880
    
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var stores: [Store]? = []
    var filteredStores: [Store]? = []

    override func viewDidLoad() {
        super.viewDidLoad()

        
        let cancelButtonAttributes: NSDictionary = [NSAttributedStringKey.foregroundColor: UIColor.white]
        UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes as? [NSAttributedStringKey : AnyObject], for: .normal)
        
        storeTableView.tableFooterView = UIView(frame: .zero)
        
        initializeGoogleMapView()
        loadStores()
    }
    
    func initializeGoogleMapView() {
        if let lat = appDelegate.myCoords?.latitude, let lng = appDelegate.myCoords?.longitude {
            latitude = lat
            longitude = lng
        }
        
        let camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 6.0)
        mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        view.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        mapView.topAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: backButton.topAnchor).isActive = true
        mapView.isMyLocationEnabled = true
        mapView.isHidden = true
    }
    
    func loadStores() {
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud?.labelText = "Loading..."
        AlamofireRequestAndResponse.sharedInstance.loadStores(latitude, longitude: longitude) { (stores, error) in
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            self.stores = stores
            self.refresh()
        }
    }
    
    func refresh() {
        filteredStores = stores?.sorted { $0.distance < $1.distance }
        let searchString = searchBar.text
        if (searchString?.length)! > 0 {
            filteredStores = filteredStores?.filter { ($0.retailerName?.localizedCaseInsensitiveContains(searchString!))! }
        }
        addMarkers()
        if filteredStores != nil {
            storeTableView.reloadData()
        }
    }
    
    func addMarkers() {
        mapView.clear()
        guard let stores = filteredStores else { return }
        for store in stores {
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: store.latitude, longitude: store.longitude)
            marker.title = store.retailerName
            marker.snippet = store.fullAddress()
            marker.map = mapView
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func changeDisplayMode(_ sender: Any) {
        if mapView.isHidden {
            mapView.isHidden = false
            storeTableView.isHidden = true
            displayModeButton.setImage(#imageLiteral(resourceName: "ic_hamburger"), for: .normal)
        } else {
            mapView.isHidden = true
            storeTableView.isHidden = false
            displayModeButton.setImage(#imageLiteral(resourceName: "ic_locator"), for: .normal)
        }
    }
    
    @IBAction func back(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

}

extension StoreLocatorViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (filteredStores?.count)!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StoreCell", for: indexPath) as! StoreCell
        
        let store = filteredStores?[indexPath.row]
        cell.retailerNameLabel.text = store?.retailerName
        cell.addressLabel.text = store?.fullAddress()
        if let distance = store?.distance {
            if distance < 1609 {
                cell.distanceLabel.text = String(format: "%.1f m", distance)
            } else {
                cell.distanceLabel.text = String(format: "%.1f miles", distance / 1609)
            }
        } else {
            cell.distanceLabel.text = ""
        }
        
        return cell
    }
}

extension StoreLocatorViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        refresh()
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = true
        
        return true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        refresh()
    }
}
