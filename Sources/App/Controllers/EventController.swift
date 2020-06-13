//
//  EventController.swift
//  App
//
//  Created by Louis de Beaumont on 02/09/2019.
//

import Vapor
import Fluent

struct EventController: RouteCollection {

  func boot(routes: RoutesBuilder) throws {
    let route = routes.grouped("api", "event")
    
    route.get(use: get)
    
    let auth = route.grouped([
      User.sessionAuthenticator(),
      // redirect middleware
    ])
    
    auth.post(use: create)
    auth.post(":eventID", "delete", use: delete)
  }
  
  func get(req: Request) -> EventLoopFuture<[EventResponse]> {
    let eventsQuery = Event.query(on: req.db).sort("date", .ascending).all()
    
    return eventsQuery.flatMap { events in
      let events = events.filter { $0.isUpcomingOrThisWeek() }
      return events.map { event in
        let artistsQuery = event.$artists.query(on: req.db).all()
        return artistsQuery.flatMap { artists in
          return artists.map { artist in
            return artist.getPreview(db: req.db)
          }
          .flatten(on: req.eventLoop)
          .map { artistPreviews in
            return EventResponse(event: event, artists: artistPreviews)
          }
        }
      }
      .flatten(on: req.eventLoop)
    }
  }
  
  func create(req: Request) -> EventLoopFuture<Event> {
    let body = req.body.description
    
    guard let data = body.data(using: .utf8) else {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Bad request body"))
    }
    
    let json: Dictionary<String, Any>
    do {
      guard let _json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, Any> else {
        return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Could not parse request body as JSON"))
      }
      json = _json
    } catch {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Could not parse request body as JSON"))
    }
    
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    
    let name = json["name"] as? String
    
    guard let dateJSON = json["date"] as? String else {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Bad value for date"))
    }
    
    guard let date = formatter.date(from: dateJSON) else {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Date value could not be converted to DateTime obejct"))
    }
    
    let description = json["description"] as? String
    
    guard let artistNames = json["artists"] as? [String] else {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Bad value for artists"))
    }
    
    let price = json["price"] as? String
    let ticketsURL = json["ticketsURL"] as? String
    
    var unsignedArtists: [UnsignedArtist] = []
    guard let unsignedArtistsJson = json["unsignedArtists"] as? [Dictionary<String, String>] else {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Bad value for unsigned artists"))
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
                      price: price,
                      ticketsURL: ticketsURL)
    
    let artistsQuery = Artist.query(on: req.db).all()
    
    if json["id"] != nil {
      guard let _id = json["id"] as? String else {
        return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Bad ID value"))
      }
      
      guard let id = UUID(uuidString: _id) else {
        return req.eventLoop.makeFailedFuture(CreateError.runtimeError("ID was not a valid UUID"))
      }
      
      return artistsQuery.flatMap { artists in
        let artists = artists.filter { artistNames.contains($0.name) }
        return self.update(req: req, id: id, updatedEvent: event, artists: artists)
      }
    }
    
    let eventSaveRequest = event.save(on: req.db)
    
    return artistsQuery.and(eventSaveRequest).flatMap { (artists, _) in
      let artists = artists.filter { artistNames.contains($0.name) }
      
      return artists.map { artist in
        return event.$artists.attach(artist, on: req.db)
      }
      .flatten(on: req.eventLoop)
      .transform(to: event)
    }
  }
  
  func update(req: Request, id: UUID, updatedEvent: Event, artists: [Artist]) -> EventLoopFuture<Event> {
    return Event.find(id, on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { event in
        event.name = updatedEvent.name
        event.date = updatedEvent.date
        event.description = updatedEvent.description
        event.unsignedArtists = updatedEvent.unsignedArtists
        event.price = updatedEvent.price
        event.ticketsURL = updatedEvent.ticketsURL
        
        let artistsDetachRequest = event.$artists.detach(artists, on: req.db)
        let eventSaveRequest = event.save(on: req.db)
        
        return artistsDetachRequest.and(eventSaveRequest).flatMap { _ in
          return artists.map { artist in
            return event.$artists.attach(artist, on: req.db)
            }
            .flatten(on: req.eventLoop)
            .transform(to: event)
        }
      }
  }
  
  func delete(req: Request) throws -> EventLoopFuture<Response> {
    let redirect = req.redirect(to: "/app/events")
    
    return Event.find(req.parameters.get("event"), on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { event in
        return event.delete(on: req.db).transform(to: redirect)
      }
  }
}
