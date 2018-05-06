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
    @IBOutlet weak var lowerBoundSlider: UISlider!
    @IBOutlet weak var upperBoundSlider: UISlider!
    @IBOutlet weak var lowerBoundLabel: UILabel!
    @IBOutlet weak var upperBoundLabel: UILabel!
    
    var pickerData: [String] = [String]()
    var dataChannelName = ""
    var lowerBound = 0.0
    var upperBound = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ARView.delegate = self
        ARView.showsStatistics = true
        
        let scene = SCNScene()
        ARView.scene = scene
        
        self.pickerView.delegate = self
        self.pickerView.dataSource = self
        
        lowerBoundSlider.isContinuous = false
        upperBoundSlider.isContinuous = false
        
        let realm = try! Realm()
        let dataSet = realm.objects(DataSet.self).first // Update this for when we have multiple datasets
        let timeSet = dataSet?.timeSets.first // Update for multiple time sets
        
        for dataChannel in (timeSet?.dataChannels)! {
            pickerData.append(dataChannel.name)
            print(dataChannel.name)
        }
        
        pickerView.reloadAllComponents()
        
        dataChannelName = pickerData[0]
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
        
        ARView.scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
        
        let realm = try! Realm()
        let dataSet = realm.objects(DataSet.self).first // Update this for when we have multiple datasets
        let timeSet = dataSet?.timeSets.first // Update for multiple time sets
        let dataChannels = timeSet?.dataChannels.filter("name == '\(dataChannelName)'")
        let dataChannel = dataChannels?.first // this works but it's shitty
        
        var latMin = 90.0
        var latMax = -90.0
        var lonMin = 180.0
        var lonMax = -180.0
        var altMin = Double.infinity
        var altMax = -Double.infinity
        var valMin = Double.infinity
        var valMax = -Double.infinity
        
        for dataPoint in (dataChannel?.dataPoints)! { // For loop to find minimun (and maximum) values
            let lat = dataPoint.lat
            let lon = dataPoint.lon
            let alt = dataPoint.alt
            let val = dataPoint.value
            
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
            if alt < altMin {
                altMin = alt
            }
            if alt > altMax {
                altMax = alt
            }
            if val < valMin {
                valMin = val
            }
            if val > valMax {
                valMax = val
            }
        }
        /*
        print(latMin)
        print(latMax)
        print(lonMin)
        print(lonMax)
        print(altMin)
        print(altMax)*/
        
        lowerBoundSlider.minimumValue = Float(valMin)
        lowerBoundSlider.maximumValue = Float(valMax)
        upperBoundSlider.minimumValue = Float(valMin)
        upperBoundSlider.maximumValue = Float(valMax)
        
        //lowerBoundSlider.value = Float(valMin)
        //upperBoundSlider.value = Float(valMax)
        
        for dataPoint in (dataChannel?.dataPoints)! {
            let lat = dataPoint.lat
            let lon = dataPoint.lon
            let alt = dataPoint.alt
            let val = dataPoint.value
            
            var ARlat = 0.0 // Local latitude coordinates in AR space
            var ARlon = 0.0 // Local longitude coordinates in AR space
            var ARalt = 0.0 // Local altitude coordinates in AR space
            
            let scaling = 500.0
            
            let latScaling = scaling // because lat goes from -90 to 90
            let lonScaling = scaling * 2
            let altScaling = 0.01
            
            ARlat = (lat - latMin) * latScaling
            ARlon = (lon - lonMin) * lonScaling
            ARalt = alt * altScaling
            
            let HSB = map(value: Float(val), minDomain: 0.35, maxDomain: 0.0, minRange: Float(lowerBound), maxRange: Float(upperBound)).clamped(to: 0.0...0.35) // 300 - 700 for CO2
            
            let box = SCNBox(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0)
            box.firstMaterial?.diffuse.contents = UIColor(
                hue: CGFloat(HSB),
                saturation: 1.0,
                brightness: 1.0,
                alpha: 1.0)
            box.firstMaterial?.isDoubleSided = true
            let boxNode = SCNNode(geometry: box)
            boxNode.position = SCNVector3(ARlat, ARalt, ARlon)  // y-axis runs paralell to gravity
            ARView.scene.rootNode.addChildNode(boxNode)
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        dataChannelName = pickerData[row]
        print("Loading new data channel: \(dataChannelName)")
        updateARData()
    }
    
    @IBAction func lowerBoundSliderChanged(_ sender: Any) {
        lowerBound = Double(lowerBoundSlider.value)
        lowerBoundLabel.text = "Lower bound: \(lowerBound)"
        updateARData()
    }
    
    @IBAction func upperBoundSliderChanged(_ sender: Any) {
        upperBound = Double(upperBoundSlider.value)
        upperBoundLabel.text = "Upper bound: \(upperBound)"
        updateARData()
    }
    
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
