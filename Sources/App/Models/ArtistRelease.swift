//
//  ArtistRelease.swift
//  App
//
//  Created by Louis de Beaumont on 21/10/2019.
//

import Foundation
import Fluent

final class ArtistRelease: Model {
  static let schema = "artistrelease"
  
  @ID(key: .id)
  var id: UUID?
  
  @Parent(key: "artist_id")
  var artist: Artist
  
  @Parent(key: "release_id")
  var release: Release
  
  init() {}
  
  init(artistID: UUID, releaseID: UUID) {
    self.$artist.id = artistID
    self.$release.id = releaseID
  }
}

extension ArtistRelease {
  struct Create: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
      database.schema(name)
        .field("id", .uuid, .identifier(auto: true))
        .field("artist_id", .uuid, .required)
        .field("release_id", .uuid, .required)
        .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
      database.schema(name).delete()
    }
  }
}
