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
      let artists = artistFutures.filter { artistNames.contains($0.name) } // Get Artist models from Strings
      let event = Event(name: name, date: date!, artists: artists, unsignedArtists: unsignedArtistNames, price: price)
      return event.save(on: req).flatMap { (_) -> EventLoopFuture<View> in
        let data = ["events": Event.query(on: req).sort(\Event.date, .ascending).all()]
        return try req.view().render("eventManagement", data)
        // Not actually used. Front-end performs a refresh which uses AppController's route.
      }
    })
  }
  
  func get(_ req: Request) throws -> Future<[Event]> {
    return Event.query(on: req).all()
  }
}
