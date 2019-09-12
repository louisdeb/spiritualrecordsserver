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
  }
  
  func index(_ req: Request) throws -> Future<View> {
    return try req.view().render("index")
  }
  
  func login(_ req: Request) throws -> Future<View> {
    return try req.view().render("login")
  }
  
  func artistManagement(_ req: Request) throws -> Future<View> {
    let data = ["artists": Artist.query(on: req).sort(\Artist.name, .ascending).all()]
    return try req.view().render("artistManagement", data)
  }
  
  func artistEdit(_ req: Request) throws -> Future<View> {
    let artist = try req.parameters.next(Artist.self)
    return artist.flatMap { (artistFuture) -> EventLoopFuture<View> in
      let data = ["artist": artistFuture]
      return try req.view().render("artistEdit", data)
    }
  }
  
  func eventManagement(_ req: Request) throws -> Future<View> {
    return try req.view().render("eventManagement")
  }
}
