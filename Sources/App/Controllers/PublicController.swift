//
//  PublicController.swift
//  App
//
//  Created by Louis de Beaumont on 29/11/2019.
//

import Vapor
import Authentication

struct PublicController: RouteCollection {
  func boot(router: Router) throws {
    router.get(use: index)
    router.get("privacy-policy", use: privacyPolicy)
  }
  
  func index(_ req: Request) throws -> Future<View> {
    return try req.view().render("publicIndex")
  }
  
  func privacyPolicy(_ req: Request) throws -> Future<View> {
    return try req.view().render("privacyPolicy")
  }
  
}
