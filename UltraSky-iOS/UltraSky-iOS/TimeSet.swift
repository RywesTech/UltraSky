//
//  TimeSet.swift
//  UltraSky-iOS
//
//  Created by Ryan Westcott on 5/3/18.
//  Copyright © 2018 Ryan Westcott. All rights reserved.
//

import Foundation
import RealmSwift

class TimeSet: Object {
    
    @objc dynamic var date = NSDate()
    var dataChannels = List<DataChannel>() //CO2, TVOC, etc...
}

