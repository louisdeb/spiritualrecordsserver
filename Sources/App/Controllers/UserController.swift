//
//  UserController.swift
//  App
//
//  Created by Louis de Beaumont on 04/09/2019.
//

import Vapor
import Crypto
import Fluent

class UserController: RouteCollection {
  
  func boot(routes: RoutesBuilder) throws {
    let usersRoute = routes.grouped("api", "user")
    
    let auth = usersRoute.grouped([
      UserAuthenticator(),
      UserSessionAuthenticator(),
      User.guardMiddleware(),
      RedirectMiddleware(),
    ])
    
    auth.post(use: login)
    auth.post("change-password", use: changePassword)
    auth.post("create-account", use: createAccount)
  }
  
  func login(_ req: Request) -> EventLoopFuture<Response> {
    guard req.auth.has(User.self) else {
      return req.eventLoop.makeFailedFuture(AuthError.runtime("Failed to log in"))
    }
    let redirect = req.redirect(to: "/app")
    return req.eventLoop.makeSucceededFuture(redirect)
  }
  
  func changePassword(req: Request) -> EventLoopFuture<Response> {
    let redirect = req.redirect(to: "/app")
    
    guard req.auth.has(User.self) else {
      return req.eventLoop.future().transform(to: redirect)
    }
    
    let user = req.auth.get(User.self)!
    
    let body = req.body.description
    
    guard let data = body.data(using: .utf8) else {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Bad request body"))
    }
    
    let json: Dictionary<String, Any>
    do {
      guard let _json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, Any> else {
        throw CreateError.runtimeError("Could not parse request body as JSON")
      }
      json = _json
    } catch {
      return req.eventLoop.makeFailedFuture(error)
    }
    
    guard let newPassword = json["new-password"] as? String else {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("New password is not a valid string"))
    }
    
    guard newPassword.count >= 8 else {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Password must be at least 8 characters long"))
    }
    
    let newPasswordHash: String
    do {
      newPasswordHash = try Bcrypt.hash(newPassword)
    } catch {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Failed to hash plaintext"))
    }
    
    user.password = newPasswordHash
    return user.save(on: req.db).transform(to: redirect)
  }
  
  func createAccount(_ req: Request) throws -> EventLoopFuture<User> {
    guard req.auth.has(User.self) else { return req.eventLoop.future(User()) }
    
    let body = req.body.description
    
    guard let data = body.data(using: .utf8) else {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Bad request body"))
    }
    
    let json: Dictionary<String, Any>
    do {
      guard let _json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, Any> else {
        throw CreateError.runtimeError("Could not parse request body as JSON")
      }
      json = _json
    } catch {
      return req.eventLoop.makeFailedFuture(error)
    }
    
    guard let username = json["username"] as? String else {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Username not a valid string"))
    }
    
    let usernameAvailable = User.query(on: req.db).all().map { users -> Bool in
      let sameNamedUsers = users.filter { $0.username == username }
      return sameNamedUsers.isEmpty
    }
    
    return usernameAvailable.flatMap { usernameAvailable in
      if (!usernameAvailable) {
        return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Username taken"))
      }
      
      guard let password = json["password"] as? String else {
        return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Password not a valid string"))
      }
      
      guard password.count >= 8 else {
        return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Password must be at least 8 characters long"))
      }
      
      let passwordHash: String
      do {
        passwordHash = try Bcrypt.hash(password)
      } catch {
        return req.eventLoop.makeFailedFuture(error)
      }
      
      let user = User(username: username, password: passwordHash)
      return user.save(on: req.db).transform(to: user)
    }
  }
}
