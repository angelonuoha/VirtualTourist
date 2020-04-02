//
//  FlickrAPI.swift
//  VirtualTourist
//
//  Created by Angel Onuoha on 1/25/20.
//  Copyright © 2020 Angel Onuoha. All rights reserved.
//

import Foundation

class FlickrAPI {
    struct Location {
        static var latitude = ""
        static var longitude = ""
    }
    
    struct photoSearchInfo {
        static var farmId = ""
        static var serverId = ""
        static var id = ""
        static var secret = ""
        
    }
    
    enum Endpoints {
        static let base = "https://www.flickr.com/services/rest"
        static let method = "?method="
        static let apiKey = "&api_key=536d74f8e5b1a4362f4428c90cb74bd0"
        static let format = "&format=json"
        
        
        
        case searchPhotos
        case getFlickrImages
        
        var stringValue: String {
            switch self {
            case .searchPhotos: return Endpoints.base + Endpoints.method + "flickr.photos.search" + Endpoints.apiKey + Endpoints.format + "&lat=\(Location.latitude)" + "&lon=\(Location.longitude)" + "&nojsoncallback=1" + "&page=1" + "&per_page=21"
            case .getFlickrImages: return "https://farm\(photoSearchInfo.farmId).staticflickr.com/\(photoSearchInfo.serverId)/\(photoSearchInfo.id)_\(photoSearchInfo.secret).jpg"
            }
        }
            
        var url: URL {
            return URL(string: stringValue)!
        }
        
    }
    
    class func getPhotos(latitude: Double, longitude: Double, completion: @escaping ([FlickrPhoto]?, Error?) -> Void) {
        Location.latitude = String(latitude)
        Location.longitude = String(longitude)
        let task = URLSession.shared.dataTask(with: Endpoints.searchPhotos.url) { (data, response, error) in
            guard let data = data else {
                completion(nil, error)
                return
            }
            do {
                let decoder = JSONDecoder()
                let responseObject = try decoder.decode(FlickrSearchResponse.self, from: data)
                completion(responseObject.photos.photo, nil)
            } catch {
                completion([], error)
            }
        }
        task.resume()
    }
    
    class func getFlickrImages(farmId: Int, serverId: String, id: String, secret: String, completion: @escaping (Data?, Error?) -> Void) {
        photoSearchInfo.farmId = String(farmId)
        photoSearchInfo.serverId = serverId
        photoSearchInfo.id = id
        photoSearchInfo.secret = secret
        let task = URLSession.shared.dataTask(with: Endpoints.getFlickrImages.url) { (data, response, error) in
            guard let data = data else {
                completion(nil, error)
                return
            }
            completion(data, nil)
        }
        task.resume()
    }

    

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}
