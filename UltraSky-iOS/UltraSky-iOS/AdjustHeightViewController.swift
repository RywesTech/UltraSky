//
//  AdjustHeightViewController.swift
//  UltraSky-iOS
//
//  Created by Ryan Westcott on 5/11/18.
//  Copyright © 2018 Ryan Westcott. All rights reserved.
//

import UIKit
import RealmSwift

class AdjustHeightViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let realm = try! Realm()
        let dataSet = realm.objects(DataSet.self).first // Update this for when we have multiple datasets
        let timeSet = dataSet?.timeSets.first // Update for multiple time sets
        let dataChannels = timeSet?.dataChannels
        
        var min = Double.infinity
        var max = -Double.infinity
        
        for dataChannel in dataChannels! {
            for dataPoint in (dataChannel.dataPoints) {
                var newAlt = dataPoint.alt + 110
                print("Current: \(dataPoint.alt)")
                print("Final: \(newAlt)")
                /*
                try! realm.write {
                    dataPoint.alt = newAlt
                }*/
                
                if(newAlt > max){
                    max = newAlt
                }
                
                if(newAlt < min){
                    min = newAlt
                }
            }
        }
        
        print(max)
        print(min)

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

}
