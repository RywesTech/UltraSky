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
        super.viewDidLoad()
        
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
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func map(value:Float, minDomain:Float, maxDomain:Float, minRange:Float, maxRange:Float) -> Float { // Map one rangle of values to another
        return minDomain + (maxDomain - minDomain) * (value - minRange) / (maxRange - minRange)
    }

}


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
