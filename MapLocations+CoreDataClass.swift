//
//  MapLocations+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Angel Onuoha on 1/28/20.
//  Copyright © 2020 Angel Onuoha. All rights reserved.
//
//

import Foundation
import CoreData
import MapKit

@objc(MapLocations)
public class MapLocations: NSManagedObject, MKAnnotation {
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var coordinates: PhotoAlbums?
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MapLocations> {
        return NSFetchRequest<MapLocations>(entityName: "MapLocations")
    }

   
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    
    convenience init(annotationLatitude: Double, annotationLongitude: Double, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entity(forEntityName: "MapLocations", in: context)!
        
        self.init(entity: entity, insertInto: context)
        
        latitude = annotationLatitude
        
        longitude = annotationLongitude
    }
    
    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude as Double, longitude: longitude as Double)
    }
    
}
