//
//  ViewController.swift
//  AddressAutoCompletionMap-ios
//
//  Created by gurjit singh on 06/08/17.
//  Copyright © 2017 gurjit singh. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let vc = SearchPlaceMapViewController(withDelegate: self)
        self.present(vc, animated: true, completion: nil)
    }

}

extension ViewController: SearchPlaceMapViewControllerDelegate {
    func searchPlaceMap(viewController: SearchPlaceMapViewController, didSearchedPlace place: CLPlacemark) {
        print(place)
    }
}

