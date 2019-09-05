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
    let usersRoute = router.grouped("app", "user")
//    usersRoute.post(use: login)
  }
//
//  func login(_ req: Request) throws -> Future<User> {
//
//  }
}
