//
//  Artist.swift
//  App
//
//  Created by Louis de Beaumont on 01/09/2019.
//

import FluentSQLite
import Vapor

final class Artist: Codable {
  var id: UUID?
  
  var name: String
  var shortDescription: String
  var description: String
  var imageURLs: [String]
  var spotify: String
  var appleMusic: String
  var instagram: String
  var facebook: String
  var website: String
  
  init(name: String, shortDescription: String?, description: String?,
       imageURLs: [String], spotify: String?, appleMusic: String?,
       instagram: String?, facebook: String?, website: String?) {
    self.name = name
    self.shortDescription = shortDescription ?? ""
    self.description = description ?? ""
    self.imageURLs = imageURLs
    self.spotify = spotify ?? ""
    self.appleMusic = appleMusic ?? ""
    self.instagram = instagram ?? ""
    self.facebook = facebook ?? ""
    self.website = website ?? ""
  }
}

extension Artist {
  var events: Siblings<Artist, Event, ArtistEventPivot> {
    return siblings()
  }
}

extension Artist: Migration {
  static func prepare(on connection: SQLiteConnection) -> Future<Void> {
    return Database.create(self, on: connection) { builder in
      try addProperties(to: builder)
      builder.unique(on: \.name)
    }
  }
}

extension Artist: SQLiteUUIDModel {}
extension Artist: Content {}
extension Artist: Parameter {}
