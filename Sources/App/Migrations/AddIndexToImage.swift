//
//  AddIndexToImage.swift
//  App
//
//  Created by Louis de Beaumont on 15/01/2020.
//

import Vapor
import FluentPostgreSQL

struct AddIndexToImage: Migration {
  typealias Database = PostgreSQLDatabase

  static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
    return Database.update(Image.self, on: conn) { builder in
      let defaultValue = PostgreSQLColumnConstraint.default(.literal(0))
      builder.field(for: \.index, type: .int, defaultValue)
    }
  }

  static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
    return conn.future()
  }
}
