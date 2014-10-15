//
//  Filter.swift
//  Filterama
//
//  Created by Alex G on 14.10.14.
//  Copyright (c) 2014 Alexey Gordiyenko. All rights reserved.
//

import Foundation
import CoreData

class Filter: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var favourited: Bool
    @NSManaged var idx: Int16
    @NSManaged var friendlyName: String
}
