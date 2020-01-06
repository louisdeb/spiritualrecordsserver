//
//  ArtistImagePivot.swift
//  App
//
//  Created by Louis de Beaumont on 21/12/2019.
//

import Foundation
import FluentPostgreSQL

final class ArtistImagePivot: PostgreSQLUUIDPivot, ModifiablePivot {
  var id: UUID?
  var artistId: Artist.ID
  var imageId: Image.ID
  
  typealias Left = Artist
  typealias Right = Image
  
  static var leftIDKey: LeftIDKey {
    return \.artistId
  }
  
  static var rightIDKey: RightIDKey {
    return \.imageId
  }
  
  init(_ artist: Artist, _ image: Image) throws {
    self.artistId = try artist.requireID()
    self.imageId = try image.requireID()
  }
  
}

extension ArtistImagePivot: Migration {
  static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
    return Database.create(self, on: conn) { (builder) in
      try addProperties(to: builder)
      builder.reference(from: \.artistId, to: \Artist.id, onDelete: .cascade)
      builder.reference(from: \.imageId, to: \Image.id, onDelete: .cascade)
    }
  }
}
