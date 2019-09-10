//
//  Event.swift
//  App
//
//  Created by Louis de Beaumont on 01/09/2019.
//

import FluentSQLite
import Vapor

final class Event: Codable {
  var id: UUID?
  
  var date: Date
  var artists: [Artist]
  
  init(date: Date, artists: [Artist]) {
    self.date = date
    self.artists = artists
  }
}

extension Event: Migration {
  static func prepare(on connection: SQLiteConnection) -> Future<Void> {
    return Database.create(self, on: connection) { builder in
      try addProperties(to: builder)
      builder.unique(on: \.id)
    }
  }
}

extension Event: SQLiteUUIDModel {}
extension Event: Content {}
extension Event: Parameter {}

// Could add a default event for open mics
