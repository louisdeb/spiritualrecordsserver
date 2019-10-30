//
//  UserController.swift
//  App
//
//  Created by Louis de Beaumont on 04/09/2019.
//

import Vapor
import Crypto

class UserController: RouteCollection {
  func boot(router: Router) throws {
    let usersRoute = router.grouped("api", "user")
    usersRoute.post(use: login)
  }

  func login(_ req: Request) throws -> Future<User> {
    let user = try req.requireAuthenticated(User.self)
    print("user authenticated")
    return Future.map(on: req) { () -> User in
      return user
    }
  }
}
