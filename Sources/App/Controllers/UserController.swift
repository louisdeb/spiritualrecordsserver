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
    auth.post("change-password", use: changePassword)
    auth.post("create-account", use: createAccount)
  }

  func login(_ req: Request) throws -> String {
    let user = try req.requireAuthenticated(User.self)
    try req.authenticateSession(user)
    return "Logged in"
  }
  
  func changePassword(_ req: Request) throws -> Future<User> {
    let user = try req.requireAuthenticated(User.self)
    
    let body = req.http.body.description
    
    guard let data = body.data(using: .utf8) else {
      throw CreateError.runtimeError("Bad request body")
    }
    
    guard let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, Any> else {
      throw CreateError.runtimeError("Could not parse request body as JSON")
    }
    
    guard let newPassword = json["new-password"] as? String else {
      throw CreateError.runtimeError("New password is not a valid string")
    }
    
    guard newPassword.count >= 8 else {
      throw CreateError.runtimeError("Password must be at least 8 characters long")
    }
    
    let newPasswordHash = try BCrypt.hash(newPassword)

    user.password = newPasswordHash
    
    return user.save(on: req)
  }
  
  func createAccount(_ req: Request) throws -> Future<User> {
    let _ = try req.requireAuthenticated(User.self)
    
    let body = req.http.body.description
    
    guard let data = body.data(using: .utf8) else {
      throw CreateError.runtimeError("Bad request body")
    }
    
    guard let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, Any> else {
      throw CreateError.runtimeError("Could not parse request body as JSON")
    }
    
    guard let username = json["username"] as? String else {
      throw CreateError.runtimeError("Username not a valid string")
    }
    
    let usernameAvailable = User.query(on: req).all().flatMap { users -> EventLoopFuture<Bool> in
      let sameNamedUsers = users.filter { $0.username == username }
      return Future.map(on: req, { () -> Bool in
        return sameNamedUsers.isEmpty
      })
    }
    
    return usernameAvailable.flatMap { usernameAvailable -> EventLoopFuture<User> in
      if (!usernameAvailable) {
        throw CreateError.runtimeError("Username in use")
      }
      
      guard let password = json["password"] as? String else {
        throw CreateError.runtimeError("Password not a valid string")
      }
      
      guard password.count >= 8 else {
        throw CreateError.runtimeError("Password must be at least 8 characters long")
      }
      
      let passwordHash = try BCrypt.hash(password)
      
      let user = User(username: username, password: passwordHash)
      
      let authenticatedUser = try req.requireAuthenticated(User.self)
      print("User \(authenticatedUser.username) created User: \(user.username)")
      
      return user.save(on: req)
    }
  }
}
