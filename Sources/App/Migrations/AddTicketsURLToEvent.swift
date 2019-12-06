//
//  AddTicketsURLToEvent.swift
//  App
//
//  Created by Louis de Beaumont on 06/12/2019.
//

import Vapor
import FluentPostgreSQL

struct AddTicketsURLToEvent: Migration {
  typealias Database = PostgreSQLDatabase

  static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
    return Database.update(Event.self, on: conn) { builder in
      let defaultValue = PostgreSQLColumnConstraint.default(.literal(""))
      builder.field(for: \.ticketsURL, type: .text, defaultValue)
    }
  }

  static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
    return conn.future()
  }
}
