//
//  PublicController.swift
//  App
//
//  Created by Louis de Beaumont on 29/11/2019.
//

import Vapor

struct PublicController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    routes.get(use: index)
    routes.get("privacy-policy", use: privacyPolicy)
  }
  
  func index(_ req: Request) throws -> EventLoopFuture<View> {
    return req.view.render("publicIndex")
  }
  
  func privacyPolicy(_ req: Request) throws -> EventLoopFuture<View> {
    return req.view.render("privacyPolicy")
  }
}
