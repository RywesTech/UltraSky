//
//  DetailViewController.swift
//  UltraSky-iOS
//
//  Created by Ryan Westcott on 4/29/18.
//  Copyright © 2018 Ryan Westcott. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import RealmSwift

class DetailViewController: UIViewController, ARSCNViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet var ARView: ARSCNView!
    @IBOutlet weak var pickerView: UIPickerView!
    var pickerData: [String] = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ARView.delegate = self
        ARView.showsStatistics = true
        
        let scene = SCNScene()
        ARView.scene = scene
        
        self.pickerView.delegate = self
        self.pickerView.dataSource = self
        
        updateARData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        ARView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        ARView.session.pause()
    }
    
    func updateARData() {
        
        let realm = try! Realm()
        let dataSet = realm.objects(DataSet.self).first
        let timeSet = dataSet?.timeSets.first
        let dataChannel = timeSet?.dataChannels.first
        
        for dataChannel in (timeSet?.dataChannels)! {
            pickerData.append(dataChannel.name)
            print(dataChannel.name)
        }
        
        pickerView.reloadAllComponents()
        
        var latMin = 180.0
        var latMax = -180.0
        var lonMin = 180.0
        var lonMax = -180.0
        var altMin = -Double.infinity
        var altMac = Double.infinity
        
        for dataPoint in (dataChannel?.dataPoints)! { // For loop to find minimun (and maximum) values
            let lat = dataPoint.lat
            let lon = dataPoint.lon
            let alt = dataPoint.alt
            
            print(lat)
            print(lon)
            print(alt)
            print("")
            
            // Use this instead of an array to perserve memory:
            if lat < latMin {
                latMin = lat
            }
            if lat > latMax {
                latMax = lat
            }
            if lon < lonMin {
                lonMin = lon
            }
            if lon > lonMax {
                lonMax = lon
            }
        }
        
        print(latMin)
        print(latMax)
        print(lonMin)
        print(lonMax)
        
        for dataPoint in (dataChannel?.dataPoints)! {
            let lat = dataPoint.lat
            let lon = dataPoint.lon
            let alt = dataPoint.alt
            
            var ARlat = 0.0 // Local latitude coordinates in AR space
            var ARlon = 0.0 // Local latitude coordinates in AR space
            var scaling = 1000.0
            
            ARlat = (lat - latMin) * scaling
            ARlon = (lon - lonMin) * scaling
            
            let box = SCNBox(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0)
            box.firstMaterial?.diffuse.contents = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
            box.firstMaterial?.isDoubleSided = true
            let boxNode = SCNNode(geometry: box)
            boxNode.position = SCNVector3(0, 0, 0)
            ARView.scene.rootNode.addChildNode(boxNode)
        }
        
        
        let box = SCNBox(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0)
        box.firstMaterial?.diffuse.contents = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
        box.firstMaterial?.isDoubleSided = true
        let boxNode = SCNNode(geometry: box)
        boxNode.position = SCNVector3(0, 0, 0)
        ARView.scene.rootNode.addChildNode(boxNode)
        
        
        /*
        var fileContent = ""
        
        if let filepath = Bundle.main.path(forResource: "data", ofType: "csv") {
            do {
                fileContent = try String(contentsOfFile: filepath)
            } catch {
                // contents could not be loaded
                print("ERROR")
            }
        } else {
            // file not found!
            print("ERROR")
        }
        
        var data: [[String]] = fileContent.components(separatedBy: "\r\n").map{ $0.components(separatedBy: ",") }
        
        data.removeFirst() // Clean up headder
        data.removeLast()  // Clean up termination row
        
        for row in data {
            let lat = Double(row[8]) // X (?)
            let lon = Double(row[9]) // Y (?)
            let alt = Double(row[5]) // Z (?)
            let value = Int(row[1])  // data
            
            let scale = 300.0
            
            let HSB = map(value: Float(value!), minDomain: 0.35, maxDomain: 0.0, minRange: 300, maxRange: 700).clamped(to: 0.0...0.35)
            
            let box = SCNBox(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0)
            box.firstMaterial?.diffuse.contents = UIColor(
                hue: CGFloat(HSB),
                saturation: 1.0,
                brightness: 1.0,
                alpha: 1.0)
            box.firstMaterial?.isDoubleSided = true
            let boxNode = SCNNode(geometry: box)
            boxNode.position = SCNVector3(lat!/(scale * 2), (alt! * 3)/scale, (-(lon! - 600))/(scale))
            ARView.scene.rootNode.addChildNode(boxNode)
        }
         */
        
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    // MARK: - Utility Functions
    
    func map(value:Float, minDomain:Float, maxDomain:Float, minRange:Float, maxRange:Float) -> Float { // Map one rangle of values to another
        return minDomain + (maxDomain - minDomain) * (value - minRange) / (maxRange - minRange)
    }
}

// MARK: - Utility Extensions

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

extension Strideable where Self.Stride: SignedInteger {
    
    func clamped(to limits: CountableClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
