//
//  EventController.swift
//  App
//
//  Created by Louis de Beaumont on 02/09/2019.
//

import Vapor
import Authentication

struct EventController: RouteCollection {
  func boot(router: Router) throws {
    let route = router.grouped("api", "event")
    route.post(use: create)
    route.get(use: get)
  }
  
  func create(_ req: Request) throws -> Future<View> {
    let body = req.http.body.description
    
    guard let data = body.data(using: .utf8) else {
      return try req.view().render("eventManagement")
    }
    
    guard let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, Any> else {
      return try req.view().render("eventManagement")
    }
    
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    
    let name = json["name"] as? String
    let date = formatter.date(from: json["date"] as! String)
    let artistNames = json["artists"] as! [String]
    let unsignedArtistNames = json["unsignedArtists"] as! [String]
    let price = json["price"] as! String
    
    return Artist.query(on: req).all().flatMap({ (artistFutures) -> Future<View> in
      let artists = artistFutures.filter { artistNames.contains($0.name) }
      return Event(name: name, date: date!, artists: artists, unsignedArtists: unsignedArtistNames, price: price)
        .save(on: req).flatMap { event -> EventLoopFuture<View> in
        let data = ["artists": Artist.query(on: req).sort(\Artist.name, .ascending).all()]
        return try req.view().render("eventManagement", data)
      }
    })
  }
  
  func get(_ req: Request) throws -> Future<[Event]> {
    return Event.query(on: req).all()
  }
}

enum CreateError: Error {
  case runtimeError(String)
}
