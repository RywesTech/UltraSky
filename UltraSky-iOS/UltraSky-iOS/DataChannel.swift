//
//  DataChannel.swift
//  UltraSky-iOS
//
//  Created by Ryan Westcott on 5/3/18.
//  Copyright © 2018 Ryan Westcott. All rights reserved.
//

import Foundation
import RealmSwift

class DataChannel: Object {
    
    @objc dynamic var name = "" //CO2, TVOC, etc...
    var dataPoints = List<DataPoint>()
}
