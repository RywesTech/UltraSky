//
//  DataSet.swift
//  UltraSky-iOS
//
//  Created by Ryan Westcott on 5/3/18.
//  Copyright © 2018 Ryan Westcott. All rights reserved.
//

import Foundation
import RealmSwift

class DataSet: Object {
    
    @objc dynamic var name = "" // Name of the data set
    @objc dynamic var createdAt = NSDate() // When it was created
    var timeSets = List<TimeSet>() // all of the different time sets
}
