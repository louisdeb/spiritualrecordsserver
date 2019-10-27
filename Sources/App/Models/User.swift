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
  var email: String
  var password: String
  
  init(email: String, password: String) {
    self.email = email
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
  static let usernameKey: UsernameKey = \User.email
  static let passwordKey: PasswordKey = \User.password
}

extension User: PasswordAuthenticatable {}
extension User: SessionAuthenticatable {}

struct AdminUser: Migration {
  typealias Database = PostgreSQLDatabase
  
  static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
    let email = "debeaumont.louis@gmail.com"
    let password = "shittyplaintextpassword"
    
    let passwordHash = try? BCrypt.hash(password)
    guard let hashedPassword = passwordHash else {
      fatalError("Failed to create admin user")
    }
    
    let user = User(email: email, password: hashedPassword)
    return user.save(on: connection).transform(to: ())
  }
  
  static func revert(on connection: PostgreSQLConnection) -> Future<Void> {
    return .done(on: connection)
  }
}
