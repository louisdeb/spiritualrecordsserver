//
//  AppController.swift
//  App
//
//  Created by Louis de Beaumont on 02/09/2019.
//

import Vapor
import Authentication

struct AppController: RouteCollection {
  func boot(router: Router) throws {
    let route = router.grouped("app")
    route.get(use: index)
    route.get("login", use: login)
    
    let artistRoute = route.grouped("artists")
    artistRoute.get(use: artistManagement)
    artistRoute.get(Artist.parameter, "edit", use: artistEdit)
    
    let eventRoute = route.grouped("events")
    eventRoute.get(use: eventManagement)
    eventRoute.get(Event.parameter, "edit", use: eventEdit)
  }
  
  func index(_ req: Request) throws -> Future<View> {
    return try req.view().render("index")
  }
  
  func login(_ req: Request) throws -> Future<View> {
    return try req.view().render("login")
  }
  
  func artistManagement(_ req: Request) throws -> Future<View> {
    let artists = Artist.query(on: req).sort(\Artist.name, .ascending).all()
    let data = ["artists": artists]
    return try req.view().render("artistManagement", data)
  }
  
  func artistEdit(_ req: Request) throws -> Future<View> {
    let artist = try req.parameters.next(Artist.self)
    let data = ["artist": artist]
    return try req.view().render("artistEdit", data)
  }
  
  func eventManagement(_ req: Request) throws -> Future<View> {
    let events = Event.query(on: req).sort(\Event.date, .ascending).all()
    
    return events.flatMap { eventFutures -> EventLoopFuture<View> in
      let events = eventFutures.filter { Event.isUpcoming(event: $0) }
      let eventResponses = try events.map { event -> Future<EventResponse> in
        return try event.artists.query(on: req).all().flatMap { artists -> EventLoopFuture<EventResponse> in
          return Future.map(on: req, { () -> EventResponse in
            return EventResponse(event: event, artists: artists)
          })
        }
      }
      .flatten(on: req)
      
      return eventResponses.flatMap { eventResponses -> EventLoopFuture<View> in
        let data = ["eventResponses": eventResponses]
        return try req.view().render("eventManagement", data)
      }
    }
  }
  
  func eventEdit(_ req: Request) throws -> Future<View> {
    let event = try req.parameters.next(Event.self)
    return event.flatMap { event -> EventLoopFuture<View> in
      return try event.artists.query(on: req).all().flatMap { artists -> EventLoopFuture<View> in
        let eventResponse = EventResponse(event: event, artists: artists)
        let data = ["eventResponse": eventResponse]
        return try req.view().render("eventEdit", data)
      }
    }
  }
}