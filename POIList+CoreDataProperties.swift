//
//  POIList+CoreDataProperties.swift
//  ParseStarterProject-Swift
//
//  Created by Charlotte Leysen on 26/02/2017.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation
import CoreData


extension POIList {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<POIList> {
        return NSFetchRequest<POIList>(entityName: "POIList");
    }

    @NSManaged public var city: String?
    @NSManaged public var name: String?
    @NSManaged public var address: String?
    @NSManaged public var area: String?
    @NSManaged public var category: String?
    @NSManaged public var audio: NSData?
    @NSManaged public var image: String?

}
