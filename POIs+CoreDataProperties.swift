//
//  POIs+CoreDataProperties.swift
//  ParseStarterProject-Swift
//
//  Created by Charlotte Leysen on 12/12/2016.
//  Copyright © 2016 Parse. All rights reserved.
//

import Foundation
import CoreData

extension POIs {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<POIs> {
        return NSFetchRequest<POIs>(entityName: "POIs");
    }

    @NSManaged public var address: String?
    @NSManaged public var area: String?
    @NSManaged public var completed: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var name: String?
    

}
