//
//  DataPoint.swift
//  UltraSky-iOS
//
//  Created by Ryan Westcott on 5/3/18.
//  Copyright © 2018 Ryan Westcott. All rights reserved.
//

import Foundation
import RealmSwift

class DataPoint: Object {
    
    @objc dynamic var lat = 0.0   // latitude
    @objc dynamic var lon = 0.0   // longitude
    @objc dynamic var alt = 0.0   // altitude
    @objc dynamic var value = 0.0 // value
    
}
