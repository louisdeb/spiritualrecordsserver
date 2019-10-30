//
//  UserController.swift
//  App
//
//  Created by Louis de Beaumont on 04/09/2019.
//

import Vapor
import Crypto
import Authentication

class UserController: RouteCollection {
  func boot(router: Router) throws {
    let usersRoute = router.grouped("api", "user")
    
    let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
    let sessionMiddleware = User.authSessionsMiddleware()
    let guardMiddleware = User.guardAuthMiddleware()
    let auth = usersRoute.grouped(basicAuthMiddleware, sessionMiddleware, guardMiddleware)
    
    auth.post(use: login)
  }

  func login(_ req: Request) throws -> String {
    let user = try req.requireAuthenticated(User.self)
    try req.authenticateSession(user)
    return "Logged in"
  }
  
//  func changePassword(_ req: Request) throws -> Future<User> {
//    let user = try req.requireAuthenticated(User.self)
//    return user.save(on: req)
//  }
}
