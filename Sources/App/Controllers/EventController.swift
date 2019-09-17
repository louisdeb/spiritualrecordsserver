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
    route.post(Event.parameter, "delete", use: delete)
  }
  
  func create(_ req: Request) throws -> Future<Event> {
    let body = req.http.body.description
    
    guard let data = body.data(using: .utf8) else {
      throw CreateError.runtimeError("Bad request body")
    }
    
    guard let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, Any> else {
      throw CreateError.runtimeError("Could not parse request body as JSON")
    }
    
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    
    let name = json["name"] as? String
    let date = formatter.date(from: json["date"] as! String)!
    let artistNames = json["artists"] as! [String]
    let unsignedArtistNames = json["unsignedArtists"] as! [String]
    let price = json["price"] as! String
    
    return Artist.query(on: req).all().flatMap({ (artistFutures) -> Future<Event> in
      let artists = artistFutures.filter { artistNames.contains($0.name) } // Get Artist models from Strings
      let event = Event(name: name, date: date, artists: artists, unsignedArtists: unsignedArtistNames, price: price)
      
      if json["id"] != nil {
        let id = UUID(uuidString: json["id"] as! String)!
        return try self.update(req, id: id, updatedEvent: event)
      }
      
      return event.save(on: req)
    })
  }
  
  func update(_ req: Request, id: UUID, updatedEvent: Event) throws -> Future<Event> {
    let eventFuture = Event.find(id, on: req)
    return eventFuture.flatMap { (event) -> EventLoopFuture<Event> in
      event?.name = updatedEvent.name
      event?.date = updatedEvent.date
      event?.artists = updatedEvent.artists
      event?.unsignedArtists = updatedEvent.unsignedArtists
      event?.price = updatedEvent.price
      
      return event!.save(on: req)
    }
  }

  func get(_ req: Request) throws -> Future<[Event]> {
    return Event.query(on: req).all()
  }
  
  func delete(_ req: Request) throws -> Future<Event> {
    let event = try req.parameters.next(Event.self)
    return event.delete(on: req)
  }
}

enum CreateError: Error {
  case runtimeError(String)
}
