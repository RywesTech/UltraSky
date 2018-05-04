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
    
    @objc dynamic var date = NSDate() // The end time that this time set was taken
    var dataChannels = List<DataChannel>() // All the channels for this time
}

