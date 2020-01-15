//
//  RemoveImageURLFromRelease.swift
//  App
//
//  Created by Louis de Beaumont on 15/01/2020.
//

import Vapor
import FluentPostgreSQL

struct RemoveImageURLFromRelease: Migration {
  typealias Database = PostgreSQLDatabase

  static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
    return Database.update(Release.self, on: conn) { builder in
//      builder.deleteField(for: \Release.imageURL)
    }
  }

  static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
    return conn.future()
  }
}
