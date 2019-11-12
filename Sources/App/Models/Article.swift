//
//  Article.swift
//  App
//
//  Created by Louis de Beaumont on 12/11/2019.
//

import FluentPostgreSQL
import Vapor

final class Article: Codable {
  var id: UUID?
  
  var title: String
  var date: Date
  var content: String
  var author: String
  var authorLink: String
  
  init(title: String, date: Date, content: String, author: String, authorLink: String?) {
    self.title = title
    self.date = date
    self.content = content
    self.author = author
    self.authorLink = authorLink ?? ""
  }
  
}

extension Article: Migration {
  static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
    return Database.create(self, on: connection) { builder in
      try addProperties(to: builder)
      builder.unique(on: \.id)
    }
  }
}

extension Article: PostgreSQLUUIDModel {}
extension Article: Content {}
extension Article: Parameter {}

