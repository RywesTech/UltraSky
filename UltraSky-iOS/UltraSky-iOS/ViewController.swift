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
    @IBOutlet weak var ConnectButton: UIButton!
    @IBOutlet weak var DurationLabel: UILabel!
    @IBOutlet weak var DataTextView: UITextView!
    
    var active = false
    var log = ""
    var timer = Timer()
    let locationManager = CLLocationManager()
    var lon: Double = 0.0
    var lat: Double = 0.0
    var CO2Level = 0
    var TVOCLevel = 0
    var millis = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        IPTextField.text = "172.20.10.13"
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
        let url = URL(string: "http://\(IPTextField.text!):9440")
        
        let task = URLSession.shared.dataTask(with: url!) { (data, response, error) in
            if let data = data {
                do {
                    // Convert the data to JSON
                    let jsonSerialized = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
                    if let json = jsonSerialized, let status = json["status"]{
                        print("Status: \(status)")
                        self.CO2Level = json["CO2Level"] as! Int
                        self.TVOCLevel = json["TVOCLevel"] as! Int
                        self.millis = json["millis"] as! Int
                        DispatchQueue.main.async {
                            self.StatusLabel.text = "Status: Connected"
                            self.ConnectButton.isEnabled = false
                            self.IPTextField.isEnabled = false
                        }
                    }
                }  catch let error as NSError {
                    print(error.localizedDescription)
                    DispatchQueue.main.async {
                        self.StatusLabel.text = "Status: Failed. \(error.localizedDescription)"
                    }
                }
            } else if let error = error {
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    self.StatusLabel.text = "Status: Failed. \(error.localizedDescription)"
                }
            }
        }
        task.resume()
    }
    
    @IBAction func StartStopPressed(_ sender: Any) {
        // Start or stop timer:
        if active {
            timer.invalidate()
            active = false
            StartStopButton.setTitle("Start", for: .normal)
            // output log
        } else {
            timer.fire()
            active = true
            StartStopButton.setTitle("Stop", for: .normal)
        }
    }
    
    @objc func update() {
        print("CO2 Level: \(CO2Level)")
        print("Millis: \(millis)")
        // Get GPS location
        // Get data from the sensor
        // Combine data and add to log
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue: CLLocationCoordinate2D = manager.location!.coordinate
        print("Got new lat, lon = \(locValue.latitude), \(locValue.longitude)")
        lat = locValue.latitude
        lon = locValue.longitude
        print("Vars lat, lon = \(lat), \(lon)")
    }
    
}
