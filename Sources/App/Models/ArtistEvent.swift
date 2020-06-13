//
//  ArtistEvent.swift
//  App
//
//  Created by Louis de Beaumont on 17/09/2019.
//

import Foundation
import Fluent

final class ArtistEvent: Model {
  static let schema = "artistevent"
  
  @ID(key: .id)
  var id: UUID?
  
  @Parent(key: "artist_id")
  var artist: Artist
  
  @Parent(key: "event_id")
  var event: Event
  
  init() {}
  
  init(artistID: UUID, eventID: UUID) {
    self.$artist.id = artistID
    self.$event.id = eventID
  }
}

extension ArtistEvent {
  struct Create: Migration {
    let name = ArtistEvent.schema
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
      database.schema(name)
        .field("id", .uuid, .identifier(auto: true))
        .field("artist_id", .uuid, .required)
        .field("event_id", .uuid, .required)
        .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
      database.schema(name).delete()
    }
  }
}
