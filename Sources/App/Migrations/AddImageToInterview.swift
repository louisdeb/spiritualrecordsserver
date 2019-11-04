//
//  AddImageToInterview.swift
//  App
//
//  Created by Louis de Beaumont on 04/11/2019.
//

import Vapor
import FluentPostgreSQL

struct AddImageToInterview: Migration {
  typealias Database = PostgreSQLDatabase

  static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
    return Database.update(Interview.self, on: conn) { builder in
      builder.field(for: \.imageURL)
    }
  }

  static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
    return conn.future()
  }
}
