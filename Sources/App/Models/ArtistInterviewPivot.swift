//
//  ArtistInterviewPivot.swift
//  App
//
//  Created by Louis de Beaumont on 31/10/2019.
//

import Vapor
import FluentPostgreSQL

final class ArtistInterviewPivot: PostgreSQLUUIDPivot, ModifiablePivot {
  var id: UUID?
  var artistId: Artist.ID
  var interviewId: Interview.ID
  
  typealias Left = Artist
  typealias Right = Interview
  
  static var leftIDKey: LeftIDKey {
    return \.artistId
  }
  
  static var rightIDKey: RightIDKey {
    return \.interviewId
  }
  
  init(_ artist: Artist, _ interview: Interview) throws {
    self.artistId = try artist.requireID()
    self.interviewId = try interview.requireID()
  }
}

extension ArtistInterviewPivot: Migration {
  static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
    return Database.create(self, on: conn) { (builder) in
      try addProperties(to: builder)
      builder.reference(from: \.artistId, to: \Artist.id, onDelete: .cascade)
      builder.reference(from: \.interviewId, to: \Interview.id, onDelete: .cascade)
    }
  }
}
