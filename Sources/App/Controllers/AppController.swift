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
    route.get("artistManagement", use: artistManagement)
    route.get("eventManagement", use: eventManagement)
  }
  
  func index(_ req: Request) throws -> Future<View> {
    return try req.view().render("index")
  }
  
  func login(_ req: Request) throws -> Future<View> {
    return try req.view().render("login")
  }
  
  func artistManagement(_ req: Request) throws -> Future<View> {
    let data = ["artists": Artist.query(on: req).all()]
    return try req.view().render("artistManagement", data)
  }
  
  func eventManagement(_ req: Request) throws -> Future<View> {
    let data = ["artists": Artist.query(on: req).all()]
    return try req.view().render("eventManagement", data)
  }
}
