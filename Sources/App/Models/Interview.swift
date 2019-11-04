//
//  Interview.swift
//  App
//
//  Created by Louis de Beaumont on 31/10/2019.
//

import FluentPostgreSQL
import Vapor

final class Interview: Codable {
  var id: UUID?
  
  var name: String
  var date: Date
  var shortDescription: String
  var description: String
  var imageURL: String
  var videoURL: String
  
  init(name: String, date: Date, shortDescription: String?, description: String?, imageURL: String?, videoURL: String?) {
    self.name = name
    self.date = date
    self.shortDescription = shortDescription ?? ""
    self.description = description ?? ""
    self.imageURL = imageURL ?? ""
    self.videoURL = videoURL ?? ""
  }
}

extension Interview {
  var artists: Siblings<Interview, Artist, ArtistInterviewPivot> {
    return siblings()
  }
}

extension Interview: Migration {
  static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
    return Database.create(self, on: connection) { builder in
      try addProperties(to: builder)
      builder.unique(on: \.id)
    }
  }
}

extension Interview: PostgreSQLUUIDModel {}
extension Interview: Content {}
extension Interview: Parameter {}
