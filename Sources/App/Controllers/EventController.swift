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
    
    let sessionMiddleware = User.authSessionsMiddleware()
    let redirectMiddleware = RedirectMiddleware(A: User.self, path: "/login")
    let auth = route.grouped(sessionMiddleware, redirectMiddleware)
    
    auth.post(use: create)
    auth.post(Event.parameter, "delete", use: delete)
  }
  
  func get(_ req: Request) throws -> Future<[EventResponse]> {
    let events = Event.query(on: req).all()
    
    return events.flatMap { _events -> EventLoopFuture<[EventResponse]> in
      let events = _events.filter { $0.isUpcomingOrThisWeek() }
      
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
    
    guard let dateJSON = json["date"] as? String else {
      throw CreateError.runtimeError("Bad date value")
    }
    
    guard let date = formatter.date(from: dateJSON) else {
      throw CreateError.runtimeError("Date value could not be converted to DateTime obejct")
    }
    
    let description = json["description"] as? String
    
    guard let artistNames = json["artists"] as? [String] else {
      throw CreateError.runtimeError("Bad value for artists")
    }
    
    let price = json["price"] as? String
    
    var unsignedArtists: [UnsignedArtist] = []
    guard let unsignedArtistsJson = json["unsignedArtists"] as? [Dictionary<String, String>] else {
      throw CreateError.runtimeError("Bad value for unsignedArtists")
    }
    
    for (_, unsignedArtistJson) in unsignedArtistsJson.enumerated() {
      let unsignedArtist = UnsignedArtist(
        name: unsignedArtistJson["name"] ?? "",
        link: unsignedArtistJson["link"] ?? ""
      )
      unsignedArtists.append(unsignedArtist)
    }
    
    let event = Event(name: name,
                      date: date,
                      description: description,
                      unsignedArtists: unsignedArtists,
                      price: price)
    
    let artists = Artist.query(on: req).all()
    
    if json["id"] != nil {
      guard let _id = json["id"] as? String else {
        throw CreateError.runtimeError("Bad id value")
      }
      
      guard let id = UUID(uuidString: _id) else {
        throw CreateError.runtimeError("Id was not a valid UUID")
      }
      
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
      event.description = updatedEvent.description
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
