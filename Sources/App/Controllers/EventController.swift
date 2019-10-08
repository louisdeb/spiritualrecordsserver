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
    route.get("currentweek", use: getCurrentWeek)
    route.post(use: create)
    route.post(Event.parameter, "delete", use: delete)
  }
  
  func get(_ req: Request) throws -> Future<[EventResponse]> {
    let events = Event.query(on: req).all()
    
    return events.flatMap { events -> EventLoopFuture<[EventResponse]> in
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
  
  func getCurrentWeek(_ req: Request) throws -> Future<[EventResponse]> {
    let lastMonday = Date().previous(.monday)
    let nextMonday = Date().next(.monday)
    
    let eventsFuture = Event.query(on: req).all()
    
    return eventsFuture.flatMap { events -> EventLoopFuture<[EventResponse]> in
      let eventsThisWeek = events.filter { $0.date > lastMonday && $0.date < nextMonday }
      
      var missingDays: [Weekday] = [.tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
      let calendar = Calendar(identifier: .gregorian)
      
      let eventResponses = try eventsThisWeek.map { event -> Future<EventResponse> in
        let day = calendar.component(.weekday, from: event.date)
        for (index, missingDay) in missingDays.enumerated() {
          if day == missingDay.rawValue {
            missingDays.remove(at: index)
          }
        }
        
        return try event.artists.query(on: req).all().flatMap { artists -> EventLoopFuture<EventResponse> in
          return Future.map(on: req, { () -> EventResponse in
            return EventResponse(event: event, artists: artists)
          })
        }
      }
      .flatten(on: req)
      
      return eventResponses.flatMap { eventResponses_ -> EventLoopFuture<[EventResponse]> in
        var eventResponses = eventResponses_
        
        for day in missingDays {
          let date = lastMonday.next(day)
          let event = Event(name: nil, date: date, description: nil, unsignedArtists: [], price: "", noEvent: true)
          let eventResponse = EventResponse(event: event, artists: [])
          eventResponses.append(eventResponse)
        }
        
        return EventLoopFuture.map(on: req, { () -> [EventResponse] in
          return eventResponses
        })
      }
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
    let description = json["description"] as? String
    let artistNames = json["artists"] as! [String]
    let unsignedArtistNames = json["unsignedArtists"] as! [String]
    let price = json["price"] as! String
    
    let artists = Artist.query(on: req).all()
    let event = Event(name: name,
                      date: date,
                      description: description,
                      unsignedArtists: unsignedArtistNames,
                      price: price)
    
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
