//
//  RealTimeViewController.swift
//  UltraSky-iOS
//
//  Created by Ryan Westcott on 5/4/18.
//  Copyright © 2018 Ryan Westcott. All rights reserved.
//

import UIKit

class RealTimeViewController: UIViewController, NRFManagerDelegate {

    @IBOutlet weak var textView: UITextView!
    var nrfManager:NRFManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nrfManager = NRFManager(
            onConnect: {
                self.log("C: ★ Connected")
        },
            onDisconnect: {
                self.log("C: ★ Disconnected")
        },
            onData: {
                (data:Data?, string:String?)->() in
                self.log("C: ⬇ Received data - String: \(string) - Data: \(data)")
        },
            autoConnect: false
        )
        
        nrfManager.verbose = true
        nrfManager.delegate = self
    }
    
    @IBAction func connect(_ sender: Any) {
        nrfManager.connect("UltSky")
    }
    
    @IBAction func start(_ sender: Any) {
        nrfManager.writeString("datalog:start")
    }
    
    @IBAction func stop(_ sender: Any) {
        nrfManager.writeString("datalog:stop")
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func log(_ string: String) {
        print(string)
        textView.text = textView.text + "\(string)\n"
        textView.scrollRangeToVisible(NSMakeRange(textView.text.characters.count , 1))
    }

}

// MARK: - NRFManagerDelegate Methods
/*
extension ViewController
{
    func nrfDidConnect(_ nrfManager:NRFManager)
    {
        self.log("D: ★ Connected")
    }
    
    func nrfDidDisconnect(_ nrfManager:NRFManager)
    {
        self.log("D: ★ Disconnected")
    }
    
    func nrfReceivedData(_ nrfManager:NRFManager, data: Data?, string: String?) {
        self.log("D: ⬇ Received data - String: \(string) - Data: \(data)")
    }
}
*/
