//
//  ReleaseImage.swift
//  App
//
//  Created by Louis de Beaumont on 14/01/2020.
//

import Foundation
import Fluent

final class ReleaseImage: Model {
  static let schema = "Image_Release"
  
  @ID(key: .id)
  var id: UUID?
  
  @Parent(key: "release_id")
  var release: Release
  
  @Parent(key: "image_id")
  var image: Image
  
  init() {}
  
  init(releaseID: UUID, imageID: UUID) {
    self.$release.id = releaseID
    self.$image.id = imageID
  }
}

extension ReleaseImage {
  struct Create: Migration {
    let name = ReleaseImage.schema
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
      database.schema(name)
        .field("id", .uuid, .identifier(auto: true))
        .field("release_id", .uuid, .required)
        .field("image_id", .uuid, .required)
        .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
      database.schema(name).delete()
    }
  }
}
