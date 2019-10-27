//
//  ArtistEventPivot.swift
//  App
//
//  Created by Louis de Beaumont on 17/09/2019.
//

import Foundation
import FluentPostgreSQL

final class ArtistEventPivot: PostgreSQLUUIDPivot, ModifiablePivot {
  var id: UUID?
  var artistId: Artist.ID
  var eventId: Event.ID
  
  typealias Left = Artist
  typealias Right = Event
  
  static var leftIDKey: LeftIDKey {
    return \.artistId
  }
  
  static var rightIDKey: RightIDKey {
    return \.eventId
  }
  
  init(_ artist: Artist, _ event: Event) throws {
    self.artistId = try artist.requireID()
    self.eventId = try event.requireID()
  }
  
}

extension ArtistEventPivot: Migration {
  static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
    return Database.create(self, on: conn) { (builder) in
      try addProperties(to: builder)
      builder.reference(from: \.artistId, to: \Artist.id, onDelete: .cascade)
      builder.reference(from: \.eventId, to: \Event.id, onDelete: .cascade)
    }
  }
}
