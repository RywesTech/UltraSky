//
//  ViewController.swift
//  UltraSky-iOS
//
//  Created by Ryan Westcott on 12/28/17.
//  Copyright © 2017 Ryan Westcott. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import MessageUI

class ViewController: UIViewController, CLLocationManagerDelegate, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var IPTextField: UITextField!
    @IBOutlet weak var StatusLabel: UILabel!
    @IBOutlet weak var ExportButton: UIButton!
    @IBOutlet weak var StartStopButton: UIButton!
    @IBOutlet weak var ConnectButton: UIButton!
    @IBOutlet weak var DurationLabel: UILabel!
    @IBOutlet weak var DataTextView: UITextView!
    
    let locationManager = CLLocationManager()
    var active = false
    var log = ""
    var timer = Timer()
    var lon: Double = 0.0
    var lat: Double = 0.0
    var alt: Double = 0.0
    var CO2Level = 0
    var TVOCLevel = 0
    var millis = 0
    var readEvery = TimeInterval(1) // Get new data every second
    var gotLastReading = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        IPTextField.text = "172.20.10.13"
        
        StartStopButton.isEnabled = false
        ExportButton.isEnabled = false
        
        log += "millis,CO2,TVOC,lat,lon,alt\n"
        
        // Ask for Authorisation from the User.
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
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
                        DispatchQueue.main.async {
                            self.StatusLabel.text = "Status: Connected"
                            self.ConnectButton.isEnabled = false
                            self.StartStopButton.isEnabled = true
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
        ExportButton.isEnabled = true
        // Start or stop timer:
        if active {
            timer.invalidate()
            active = false
            StartStopButton.setTitle("Start", for: .normal)
            // output log
        } else {
            timer = Timer.scheduledTimer(timeInterval: self.readEvery, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
            active = true
            StartStopButton.setTitle("Stop", for: .normal)
        }
    }
    
    @objc func update() {
        print("UPDATING")
        
        if(gotLastReading) {
            print("GOT LAST READING")
            let url = URL(string: "http://\(IPTextField.text!):9440")
            
            let task = URLSession.shared.dataTask(with: url!) { (data, response, error) in
                if let data = data {
                    do {
                        // Convert the data to JSON
                        let jsonSerialized = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
                        if let json = jsonSerialized {
                            self.CO2Level = json["CO2Level"] as! Int
                            self.TVOCLevel = json["TVOCLevel"] as! Int
                            self.millis = json["millis"] as! Int
                            DispatchQueue.main.async {
                                print("CO2 Level: \(self.CO2Level)")
                                print("Millis: \(self.millis)")
                                self.StatusLabel.text = "Status: Running"
                                self.DurationLabel.text = "Duration: \(self.millis/1000) seconds"
                                
                                let addToLog = "\(self.millis),\(self.CO2Level),\(self.TVOCLevel),\(self.lat),\(self.lon),\(self.alt)"
                                self.log += "\(addToLog)\n"
                                self.DataTextView.text = self.log
                                self.DataTextView.scrollToBotom()
                                
                                self.gotLastReading = true
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
        gotLastReading = false
    }
    
    @IBAction func ExportPressed(_ sender: Any) {
        export()
    }
    
    func export() {
        
        let fileName = "data.csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        let csvText = log
        
        do {
            try csvText.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
            
            if MFMailComposeViewController.canSendMail() {
                let emailController = MFMailComposeViewController()
                emailController.mailComposeDelegate = self
                emailController.setToRecipients(["westcottr@go.oes.edu"])
                emailController.setSubject("UltraSky data export")
                emailController.setMessageBody("Hi Ryan,\n\nThe CSV data export is attached.\n\n\nSent from the UltraSky app.", isHTML: false)
                
                do {
                    try emailController.addAttachmentData(NSData(contentsOf: path!) as Data, mimeType: "text/csv", fileName: "data.csv")
                }
                
                present(emailController, animated: true, completion: nil)
            }
            
        } catch {
            
            print("Failed to create file")
            print("\(error)")
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        // Dismiss the mail compose view controller.
        controller.dismiss(animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error){
        locationManager.stopUpdatingLocation()
        print("Location Manager Error:")
        print(error)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //print("Got new location")
        let locValue: CLLocationCoordinate2D = manager.location!.coordinate
        lat = locValue.latitude
        lon = locValue.longitude
        alt = (manager.location?.altitude)!
        //print("Got new lat, lon = \(lat), \(lon)")
    }
    
}


extension UITextView {
    
    func scrollToBotom() {
        let range = NSMakeRange(text.characters.count - 1, 1);
        scrollRangeToVisible(range);
    }
    
}
