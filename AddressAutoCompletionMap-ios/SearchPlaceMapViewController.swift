//
//  AddressHelperMapViewController.swift
//  AddressAutoCompletionMap-ios
//
//  Created by gurjit singh on 06/08/17.
//  Copyright © 2017 gurjit singh. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

struct Location {
    var latitude: Double
    var logitude: Double
}

struct SearchedAddress {
    var streetAddress: String
    var areaAddress: String?
    var city: String
    var state: String
    var country: String
    var postalCode: String
    var location: Location
}

protocol SearchPlaceMapViewControllerDelegate {
    func searchPlaceMap(viewController: SearchPlaceMapViewController, didSearchedPlace place: CLPlacemark)
}

class SearchPlaceMapViewController: UIViewController {
    var delegate: SearchPlaceMapViewControllerDelegate
    let locationManager = CLLocationManager()
    var searchCompleter = MKLocalSearchCompleter()
    var searchResults = [MKLocalSearchCompletion]()
    
    var searchedPlace: CLPlacemark? = nil
    var isSearchingInProgress: Bool = false {
        didSet {
            if isSearchingInProgress {
                searchedPlace = nil
                DetailAddressLbl.text = ""
                AddressLbl.text = ""
            }
        }
    }
    
    @IBOutlet weak var searchResultsTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var AddressLbl: UILabel!
    @IBOutlet weak var DetailAddressLbl: UILabel!
    
//MARK: Initilisation
    required init(withDelegate delegate: SearchPlaceMapViewControllerDelegate) {
        self.delegate = delegate
        super.init(nibName: "SearchPlaceMapViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
//MARK: View load helper
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _setup()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    private func _setup() {
        searchResultsTableView.isHidden = true
        
        mapView.delegate = self
        
        searchCompleter.delegate = self
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
    }

    // change map view position with new coordinates.
    func refeshMap(withCoordinate coordinate: CLLocationCoordinate2D){
        let center = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        self.mapView.setRegion(region, animated: true)
    }
//MARK: Setting Bottom view
    func refreshAddressView(withPlace place: CLPlacemark) {
        searchedPlace = place
        if let addressDict = place.addressDictionary as? [String:AnyObject] {
            print(addressDict)
            AddressLbl.text = addressDict["Name"] as? String ?? addressDict["SubLocality"] as? String ?? addressDict["Locality"] as? String ?? addressDict["City"] as? String
            
            var detailAddress = ""
            if let city = addressDict["City"] as? String {
                detailAddress += city
            }
            if let distric = addressDict["SubAdministrativeArea"] as? String {
                detailAddress += "\n" + distric
            }
            if let state = addressDict["State"] as? String {
                detailAddress += "\n" + state
            }
            if let country = addressDict["Country"] as? String {
                detailAddress += "," + country
            }
            if let postalCode = addressDict["ZIP"] as? String {
                detailAddress += "\n" + postalCode
            }
            DetailAddressLbl.text = detailAddress.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
    }
    func getAddress(witLocation location: CLLocation) {
        let coder = CLGeocoder()
        isSearchingInProgress = true
        coder.reverseGeocodeLocation(location) { (placeMarkers, error) in
            self.isSearchingInProgress = false
            if let place = placeMarkers?.first {
                self.refreshAddressView(withPlace: place)
            }
        }
    }
    
//MARK: UI Actions
    @IBAction func barButtonCancelButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func selectAddressButtonClicked(_ sender: Any) {
        if let _ = searchedPlace {
            self.delegate.searchPlaceMap(viewController: self, didSearchedPlace: searchedPlace!)
        }
    }
}

//MARK: SearchBar Delegates
extension SearchPlaceMapViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == ""  {
            self.searchResultsTableView.isHidden = true
            return
        }
        self.searchCompleter.queryFragment = searchText
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.text = ""
        self.searchResultsTableView.isHidden = true
    }
}

// MARK: Search Completor Delagates
extension SearchPlaceMapViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.searchResults = completer.results
        self.searchResultsTableView.reloadData()
        self.searchResultsTableView.isHidden = (searchResults.count > 0 && searchBar.isFirstResponder) ? false : true
    }
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Error::", error.localizedDescription)
    }
}

//MARK: MapView Delegates
extension SearchPlaceMapViewController: MKMapViewDelegate {
    func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: Error) {
        print("Error:", error.localizedDescription)
    }
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print(mapView.centerCoordinate)
        let location = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        self.getAddress(witLocation: location)
    }
}

//MARK: Tableview UITableViewDelegate, UITableViewDataSource
extension SearchPlaceMapViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = searchResults[indexPath.row].title
        cell.detailTextLabel?.text = searchResults[indexPath.row].subtitle
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.searchResultsTableView.isHidden = true
        self.searchBar.resignFirstResponder()
        self.searchBar.text = ""
        
        let completion = searchResults[indexPath.row]
        let searchRequest = MKLocalSearchRequest(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        
        isSearchingInProgress = true
        search.start { (response, error) in
            self.isSearchingInProgress = false
            guard let placeMarker = response?.mapItems.first?.placemark else {  return  }
            self.refeshMap(withCoordinate: placeMarker.coordinate)
        }
    }
    
}

//MARK: Location Managr Delegates
extension SearchPlaceMapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            self.locationManager.startUpdatingLocation()
            self.locationManager.requestLocation()
        } else {
            //TODO: Show alert to turn on locatin Access in app settings
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.refeshMap(withCoordinate: location.coordinate)
            self.locationManager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager Error: ", error.localizedDescription)
    }
}

