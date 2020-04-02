//
//  FlickrSearchResponse.swift
//  VirtualTourist
//
//  Created by Angel Onuoha on 1/27/20.
//  Copyright © 2020 Angel Onuoha. All rights reserved.
//

import Foundation
import UIKit

struct FlickrSearchResponse: Codable {
    let photos: FlickrResponse
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case photos
        case status = "stat"
    }
    
}

struct FlickrResponse: Codable {
    let page: Int
    let totalPages: Int
    let perPage: Int
    let totalPhotos: String
    let photo: [FlickrPhoto]
    
    enum CodingKeys: String, CodingKey {
        case page
        case totalPages = "pages"
        case perPage = "perpage"
        case totalPhotos = "total"
        case photo
    }
}

struct FlickrPhoto: Codable {
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let ispublic: Int
    let isfriend: Int
    let isfamily: Int
}
