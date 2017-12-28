//
//  ViewController.swift
//  UltraSky-iOS
//
//  Created by Ryan Westcott on 12/28/17.
//  Copyright © 2017 Ryan Westcott. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var IPTextField: UITextField!
    @IBOutlet weak var StatusLabel: UILabel!
    @IBOutlet weak var StartStopButton: UIButton!
    @IBOutlet weak var DurationLabel: UILabel!
    @IBOutlet weak var DataTextView: UITextView!
    
    var active = false
    var log = ""
    var timer = Timer()
    let locationManager = CLLocationManager()
    var lon: Double = 0.0
    var lat: Double = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        IPTextField.text = "172.20.1.13"
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
    }
    
    @IBAction func ConnectPressed(_ sender: Any) {
        // send a request to see if the server is up
    }
    
    @IBAction func StartStopPressed(_ sender: Any) {
        // Start or stop timer
        if active {
            timer.invalidate()
            // output log
        } else {
            timer.fire()
        }
    }
    
    @objc func update() {
        // Get GPS location
        // Get data from the sensor
        // Combine data and add to log
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        var locValue:CLLocationCoordinate2D = manager.location!.coordinate
        print("locations = \(locValue.latitude) \(locValue.longitude)")
    }
    
}
