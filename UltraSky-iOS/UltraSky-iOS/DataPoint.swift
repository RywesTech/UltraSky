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
    
    //@objc dynamic var time = NSDate()
    @objc dynamic var value = 0.0
}
