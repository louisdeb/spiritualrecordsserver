//
//  RemoveImageURLsFromArtist.swift
//  App
//
//  Created by Louis de Beaumont on 15/01/2020.
//

import Vapor
import FluentPostgreSQL

struct RemoveImageURLsFromArtist: Migration {
  typealias Database = PostgreSQLDatabase

  static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
    return Database.update(Artist.self, on: conn) { builder in
//      builder.deleteField(for: \Artist.imageURLs)
    }
  }

  static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
    return conn.future()
  }
}
