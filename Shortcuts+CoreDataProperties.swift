//
//  Shortcuts+CoreDataProperties.swift
//  ParseStarterProject-Swift
//
//  Created by Charlotte Leysen on 31/01/2017.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation
import CoreData


extension Shortcuts {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Shortcuts> {
        return NSFetchRequest<Shortcuts>(entityName: "Shortcuts");
    }

    @NSManaged public var city: String?
    @NSManaged public var borough: String?
    @NSManaged public var username: String?
    @NSManaged public var password: String?

}
