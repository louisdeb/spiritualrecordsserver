//
//  Artist.swift
//  App
//
//  Created by Louis de Beaumont on 01/09/2019.
//

import FluentSQLite
import Vapor

final class Artist: Codable {
  var id: UUID?
  
  var name: String
}

extension Artist: Migration {
  static func prepare(on connection: SQLiteConnection) -> Future<Void> {
    return Database.create(self, on: connection) { builder in
      try addProperties(to: builder)
      builder.unique(on: \.name)
    }
  }
}

extension Artist: SQLiteUUIDModel {}
extension Artist: Content {}
extension Artist: Parameter {}
