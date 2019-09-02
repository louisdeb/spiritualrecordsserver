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
    route.get("home", use: home)
    route.get("artistManagement", use: artistManagement)
    route.get("eventManagement", use: eventManagement)
  }
  
  func home(_ req: Request) throws -> Future<View> {
    return try req.view().render("home")
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
