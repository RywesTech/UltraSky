//
//  CSVToDBViewController.swift
//  UltraSky-iOS
//
//  Created by Ryan Westcott on 5/3/18.
//  Copyright © 2018 Ryan Westcott. All rights reserved.
//

import UIKit
import RealmSwift

class CSVToDBViewController: UIViewController {

    override func viewDidLoad() {
        let realm = try! Realm()
        
        /*
        try! realm.write {
            realm.deleteAll() // DELETE THIS OR EVERYTHING GOES TO SHIT
        }*/
        
        
        super.viewDidLoad()
        
        let dataSet = DataSet()
        dataSet.name = "New Dataset"
        dataSet.createdAt = NSDate()
        
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
        
        let timeSet = TimeSet()
        timeSet.date = NSDate()
        
        let CO2dataChannel = DataChannel()
        CO2dataChannel.name = "CO2"
        
        let TVOCdataChannel = DataChannel()
        TVOCdataChannel.name = "TVOC"
        
        var data: [[String]] = fileContent.components(separatedBy: "\r\n").map{ $0.components(separatedBy: ",") }
        
        data.removeFirst() // Clean up headder
        data.removeLast()  // Clean up termination row
        
        for row in data {
            let lat = Double(row[6]) // X (?)
            let lon = Double(row[7]) // Y (?)
            let alt = Double(row[5]) // Z (?)
            let value = Int(row[1])  // data
            
            //let scale = 300.0
            
            //let HSB = map(value: Float(value!), minDomain: 0.35, maxDomain: 0.0, minRange: 300, maxRange: 700).clamped(to: 0.0...0.35)
            
            let CO2 = Int(row[1])
            let TVOC = Int(row[2])
            
            let CO2DataPoint = DataPoint()
            CO2DataPoint.lat = lat!
            CO2DataPoint.lon = lon!
            CO2DataPoint.alt = alt!
            CO2DataPoint.value = Double(CO2!)
            
            let TVOCDataPoint = DataPoint()
            TVOCDataPoint.lat = lat!
            TVOCDataPoint.lon = lon!
            TVOCDataPoint.alt = alt!
            TVOCDataPoint.value = Double(TVOC!)
            
            CO2dataChannel.dataPoints.append(CO2DataPoint)
            TVOCdataChannel.dataPoints.append(TVOCDataPoint)
            
            /*
            let box = SCNBox(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0)
            box.firstMaterial?.diffuse.contents = UIColor(
                hue: CGFloat(HSB),
                saturation: 1.0,
                brightness: 1.0,
                alpha: 1.0)
            box.firstMaterial?.isDoubleSided = true
            let boxNode = SCNNode(geometry: box)
            boxNode.position = SCNVector3(lat!/(scale * 2), (alt! * 3)/scale, (-(lon! - 600))/(scale))
            ARView.scene.rootNode.addChildNode(boxNode)*/
        }
        
        timeSet.dataChannels.append(CO2dataChannel)
        timeSet.dataChannels.append(TVOCdataChannel)
        
        dataSet.timeSets.append(timeSet)
        
        //let realm = try! Realm()
        try! realm.write {
            realm.add(dataSet)
            print(dataSet.name)
        }
        
    }
    
    func map(value:Float, minDomain:Float, maxDomain:Float, minRange:Float, maxRange:Float) -> Float { // Map one rangle of values to another
        return minDomain + (maxDomain - minDomain) * (value - minRange) / (maxRange - minRange)
    }

}
