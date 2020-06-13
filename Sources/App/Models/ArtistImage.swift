//
//  ArtistImage.swift
//  App
//
//  Created by Louis de Beaumont on 21/12/2019.
//

import Foundation
import Fluent

final class ArtistImage: Model {
  static let schema = "artistimage"
  
  @ID(key: .id)
  var id: UUID?
  
  @Parent(key: "artist_id")
  var artist: Artist
  
  @Parent(key: "image_id")
  var image: Image
  
  init() {}
  
  init(artistID: UUID, imageID: UUID) {
    self.$artist.id = artistID
    self.$image.id = imageID
  }
}

extension ArtistImage {
  struct Create: Migration {
    let name = ArtistImage.schema
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
      database.schema(name)
        .field("id", .uuid, .identifier(auto: true))
        .field("artist_id", .uuid, .required)
        .field("image_id", .uuid, .required)
        .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
      database.schema(name).delete()
    }
  }
}
