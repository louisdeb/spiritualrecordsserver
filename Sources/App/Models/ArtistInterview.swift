//
//  ArtistInterview.swift
//  App
//
//  Created by Louis de Beaumont on 31/10/2019.
//

import Vapor
import Fluent

final class ArtistInterview: Model {
  static let schema = "artistinterview"
  
  @ID(key: .id)
  var id: UUID?
  
  @Parent(key: "artist_id")
  var artist: Artist
  
  @Parent(key: "interview_id")
  var interview: Interview
  
  init() {}
  
  init(artistID: UUID, interviewID: UUID) {
    self.$artist.id = artistID
    self.$interview.id = interviewID
  }
}

extension ArtistInterview {
  struct Create: Migration {
    let name = ArtistInterview.schema
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
      database.schema(name)
        .field("id", .uuid, .identifier(auto: true))
        .field("artist_id", .uuid, .required)
        .field("interview_id", .uuid, .required)
        .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
      database.schema(name).delete()
    }
  }
}
