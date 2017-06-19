//
//  Shortcuts+CoreDataProperties.swift
//  ParseStarterProject-Swift
//
//  Created by Charlotte Leysen on 26/02/2017.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation
import CoreData


extension Shortcuts {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Shortcuts> {
        return NSFetchRequest<Shortcuts>(entityName: "Shortcuts");
    }

    @NSManaged public var password: String?
    @NSManaged public var username: String?

}
