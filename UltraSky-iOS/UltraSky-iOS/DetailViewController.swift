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

class DetailViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var ARView: ARSCNView!
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ARView.delegate = self
        ARView.showsStatistics = true
        
        let scene = SCNScene()
        ARView.scene = scene
        
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
