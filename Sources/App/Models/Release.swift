//
//  Release.swift
//  App
//
//  Created by Louis de Beaumont on 21/10/2019.
//

import FluentSQLite
import Vapor

final class Release: Codable {
  var id: UUID?
  
  var name: String
  var date: Date
  var description: String
  var imageURL: String
  var spotify: String
  var appleMusic: String
  
  init(name: String, date: Date, description: String?, imageURL: String, spotify: String?, appleMusic: String?) {
    self.name = name
    self.date = date
    self.description = description ?? ""
    self.imageURL = imageURL
    self.spotify = spotify ?? ""
    self.appleMusic = appleMusic ?? ""
  }
  
}

extension Release {
  var artists: Siblings<Release, Artist, ArtistReleasePivot> {
    return siblings()
  }
}

extension Release: Migration {
  static func prepare(on connection: SQLiteConnection) -> Future<Void> {
    return Database.create(self, on: connection) { builder in
      try addProperties(to: builder)
      builder.unique(on: \.id)
    }
  }
}

extension Release: SQLiteUUIDModel {}
extension Release: Content {}
extension Release: Parameter {}
