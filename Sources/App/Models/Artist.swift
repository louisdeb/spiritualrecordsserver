//
//  Artist.swift
//  App
//
//  Created by Louis de Beaumont on 01/09/2019.
//

import FluentPostgreSQL
import Vapor

final class Artist: Codable {
  var id: UUID?
  
  var name: String
  var shortDescription: String
  var description: String
  var spotify: String
  var appleMusic: String
  var googlePlay: String
  var instagram: String
  var facebook: String
  var website: String
  
  init(name: String, shortDescription: String?, description: String?,
       spotify: String?, appleMusic: String?, googlePlay: String?,
       instagram: String?, facebook: String?, website: String?) {
    self.name = name
    self.shortDescription = shortDescription ?? ""
    self.description = description ?? ""
    self.spotify = spotify ?? ""
    self.appleMusic = appleMusic ?? ""
    self.googlePlay = googlePlay ?? ""
    self.instagram = instagram ?? ""
    self.facebook = facebook ?? ""
    self.website = website ?? ""
  }
  
  final class Preview: Codable {
    var id: UUID?
    var name: String
    var shortDescription: String
    var imageURL: String
    
    init(id: UUID?, name: String, shortDescription: String, imageURL: String) {
      self.id = id
      self.name = name
      self.shortDescription = shortDescription
      self.imageURL = imageURL
    }
  }
  
  final class Profile: Codable {
    var artist: Artist
    var images: [Image]
    
    init(artist: Artist, images: [Image]) {
      self.artist = artist
      self.images = images
    }
  }
}

extension Artist {
  var images: Siblings<Artist, Image, ArtistImagePivot> {
    return siblings()
  }
}

extension Artist {
  var events: Siblings<Artist, Event, ArtistEventPivot> {
    return siblings()
  }
}

extension Artist {
  var releases: Siblings<Artist, Release, ArtistReleasePivot> {
    return siblings()
  }
}

extension Artist: Migration {
  static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
    return Database.create(self, on: connection) { builder in
      try addProperties(to: builder)
      builder.unique(on: \.name)
    }
  }
}

extension Artist: PostgreSQLUUIDModel {}
extension Artist: Content {}
extension Artist: Parameter {}

extension Artist.Preview: Content {}
extension Artist.Profile: Content {}

extension Artist {
  func getPreview(_ req: Request) throws -> Future<Artist.Preview> {
    return try images.query(on: req).sort(\Image.index, .ascending).first().flatMap { image -> EventLoopFuture<Artist.Preview> in
      let imageURL = image?.url ?? ""
      return Future.map(on: req, { () -> Artist.Preview in
        return Artist.Preview(id: self.id, name: self.name, shortDescription: self.shortDescription, imageURL: imageURL)
      })
    }
  }
}

extension Artist {
  func getProfile(_ req: Request) throws -> Future<Artist.Profile> {
    return try images.query(on: req).sort(\Image.index, .ascending).all().flatMap { images -> EventLoopFuture<Artist.Profile> in
      return Future.map(on: req, { () -> Artist.Profile in
        return Artist.Profile(artist: self, images: images)
      })
    }
  }
}
