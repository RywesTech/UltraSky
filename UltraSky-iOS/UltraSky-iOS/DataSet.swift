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
    
    @objc dynamic var name = ""
    @objc dynamic var createdAt = NSDate()
    var timeSets = List<TimeSet>()
}
