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
    route.get(use: get)
    route.post(use: create)
    route.post(Event.parameter, "delete", use: delete)
  }
  
  func get(_ req: Request) throws -> Future<[EventResponse]> {
    return Event.query(on: req).all().flatMap { events -> EventLoopFuture<[EventResponse]> in
      return try events.map { event -> Future<EventResponse> in
        return try event.artists.query(on: req).all().flatMap { artists -> EventLoopFuture<EventResponse> in
          return Future.map(on: req, { () -> EventResponse in
            return EventResponse(event: event, artists: artists)
          })
        }
      }
      .flatten(on: req)
    }
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
    
    let artists = Artist.query(on: req).all()
    let event = Event(name: name, date: date, unsignedArtists: unsignedArtistNames, price: price)
    
    if json["id"] != nil {
      let id = UUID(uuidString: json["id"] as! String)!
      return artists.flatMap { allArtists -> EventLoopFuture<Event> in
        let artists = allArtists.filter { artistNames.contains($0.name) }
        return try self.update(req, id: id, updatedEvent: event, artists: artists)
      }
    }
    
    return flatMap(artists, event.save(on: req), { (allArtists, event) -> EventLoopFuture<Event> in
      let artists = allArtists.filter { artistNames.contains($0.name) }
      
      return artists.map { artist in
        return event.artists.attach(artist, on: req)
      }
      .flatten(on: req)
      .transform(to: event)
    })
  }
  
  func update(_ req: Request, id: UUID, updatedEvent: Event, artists: [Artist]) throws -> Future<Event> {
    let eventFindFuture = Event.find(id, on: req)
    
    return eventFindFuture.flatMap { event_ -> EventLoopFuture<Event> in
      guard let event = event_ else {
        throw CreateError.runtimeError("Could not find event to update")
      }
      
      event.name = updatedEvent.name
      event.date = updatedEvent.date
      event.unsignedArtists = updatedEvent.unsignedArtists
      event.price = updatedEvent.price
      
      return flatMap(event.artists.detachAll(on: req), event.save(on: req), { (_, event) in
        return artists.map { artist in
          return event.artists.attach(artist, on: req)
          }
          .flatten(on: req)
          .transform(to: event)
      })
    }
  }
  
  func delete(_ req: Request) throws -> Future<Event> {
    let event = try req.parameters.next(Event.self)
    return event.delete(on: req)
  }
}

enum CreateError: Error {
  case runtimeError(String)
}
