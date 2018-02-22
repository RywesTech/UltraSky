//
//  ViewController.swift
//  UltraSky Visualization
//
//  Created by Ryan Westcott on 2/15/18.
//  Copyright © 2018 Ryan Westcott. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        //let scene = SCNScene(named: "art.scnassets/ship.scn")!
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        let file = "data.csv" //this is the file. we will write to and read from it
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
        //print(fileContent)
        var data: [[String]] = fileContent.components(separatedBy: "\r\n").map{ $0.components(separatedBy: ",") }
        data.removeFirst()
        data.removeLast()
        //print(data)
        
        for row in data {
            let lat = Double(row[8])
            let lon = Double(row[9])
            let alt = Double(row[5])
            let co2 = Int(row[1])
            
            //print(lat!/50)
            
            let scale = 300.0
            
            let HSB = map(value: Float(co2!), minDomain: 0.35, maxDomain: 0.0, minRange: 300, maxRange: 700).clamped(to: 0.0...0.35)
            print(HSB)
            
            
            let box = SCNBox(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0)
            box.firstMaterial?.diffuse.contents = UIColor(
                hue: CGFloat(HSB),
                saturation: 1.0,
                brightness: 1.0,
                alpha: 1.0)
            box.firstMaterial?.isDoubleSided = true
            let boxNode = SCNNode(geometry: box)
            boxNode.position = SCNVector3(lat!/(scale * 2), (alt! * 3)/scale, (-(lon! - 600))/(scale))
            sceneView.scene.rootNode.addChildNode(boxNode)
        }
        
        let plane = SCNPlane(width: 1, height: 1)
        
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "ground.png")
        plane.materials = [material]
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3(1,-0.45,-0.08)
        planeNode.scale = SCNVector3(2,2,2)
        planeNode.eulerAngles = SCNVector3(-1.5708,-0.15,0)
        
        sceneView.scene.rootNode.addChildNode(planeNode)
        /*
        let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        box.firstMaterial?.diffuse.contents = UIColor.blue
        box.firstMaterial?.isDoubleSided = true
        let boxNode = SCNNode(geometry: box)
        boxNode.position = SCNVector3(0, 0, 0)
        sceneView.scene.rootNode.addChildNode(boxNode)*/
        
        var timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.update), userInfo: nil, repeats: false)
        
        /*
        let box2 = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        box2.firstMaterial?.diffuse.contents = UIColor.green
        box2.firstMaterial?.isDoubleSided = true
        let boxNode2 = SCNNode(geometry: box2)
        boxNode2.position = SCNVector3(0, 0, 1)
        sceneView.scene.rootNode.addChildNode(boxNode2)*/
    }
    
    @objc func update(){
        print("RESET")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    func map(value:Float, minDomain:Float, maxDomain:Float, minRange:Float, maxRange:Float) -> Float {
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
