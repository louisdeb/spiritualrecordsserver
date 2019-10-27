//
//  Release.swift
//  App
//
//  Created by Louis de Beaumont on 21/10/2019.
//

import FluentPostgreSQL
import Vapor

final class Release: Codable {
  var id: UUID?
  
  var name: String
  var date: Date
  var description: String
  var imageURL: String
  var spotify: String
  var appleMusic: String
  var googlePlay: String
  
  init(name: String, date: Date, description: String?, imageURL: String,
       spotify: String?, appleMusic: String?, googlePlay: String?) {
    self.name = name
    self.date = date
    self.description = description ?? ""
    self.imageURL = imageURL
    self.spotify = spotify ?? ""
    self.appleMusic = appleMusic ?? ""
    self.googlePlay = googlePlay ?? ""
  }
  
}

extension Release {
  var artists: Siblings<Release, Artist, ArtistReleasePivot> {
    return siblings()
  }
}

extension Release: Migration {
  static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
    return Database.create(self, on: connection) { builder in
      try addProperties(to: builder)
      builder.unique(on: \.id)
    }
  }
}

extension Release: PostgreSQLUUIDModel {}
extension Release: Content {}
extension Release: Parameter {}
