//
//  User.swift
//  App
//
//  Created by Louis de Beaumont on 04/09/2019.
//

import FluentPostgreSQL
import Vapor
import Authentication

final class User: Codable {
  var id: UUID?
  var username: String
  var password: String
  
  init(username: String, password: String) {
    self.username = username
    self.password = password
  }
}

extension User: Migration {
  static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
    return Database.create(self, on: connection) { builder in
      try addProperties(to: builder)
      builder.unique(on: \.id)
    }
  }
}

extension User: PostgreSQLUUIDModel {}
extension User: Content {}
extension User: Parameter {}

extension User: BasicAuthenticatable {
  static let usernameKey: UsernameKey = \User.username
  static let passwordKey: PasswordKey = \User.password
}

extension User: PasswordAuthenticatable {}
extension User: SessionAuthenticatable {}
