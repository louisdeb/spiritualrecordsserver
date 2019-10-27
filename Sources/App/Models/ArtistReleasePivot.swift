//
//  ArtistReleasePivot.swift
//  App
//
//  Created by Louis de Beaumont on 21/10/2019.
//

import Foundation
import FluentPostgreSQL

final class ArtistReleasePivot: PostgreSQLUUIDPivot, ModifiablePivot {
  var id: UUID?
  var artistId: Artist.ID
  var releaseId: Release.ID
  
  typealias Left = Artist
  typealias Right = Release
  
  static var leftIDKey: LeftIDKey {
    return \.artistId
  }
  
  static var rightIDKey: RightIDKey {
    return \.releaseId
  }
  
  init(_ artist: Artist, _ release: Release) throws {
    self.artistId = try artist.requireID()
    self.releaseId = try release.requireID()
  }
  
}

extension ArtistReleasePivot: Migration {
  static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
    return Database.create(self, on: conn) { (builder) in
      try addProperties(to: builder)
      builder.reference(from: \.artistId, to: \Artist.id, onDelete: .cascade)
      builder.reference(from: \.releaseId, to: \Release.id, onDelete: .cascade)
    }
  }
}
