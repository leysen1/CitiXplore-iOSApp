//
//  POI+CoreDataProperties.swift
//  ParseStarterProject-Swift
//
//  Created by Charlotte Leysen on 31/12/2016.
//  Copyright © 2016 Parse. All rights reserved.
//

import Foundation
import CoreData


extension POI {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<POI> {
        return NSFetchRequest<POI>(entityName: "POI");
    }

    @NSManaged public var address: String?
    @NSManaged public var area: String?
    @NSManaged public var completed: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var name: String?
    @NSManaged public var email: String?

}
