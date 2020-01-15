//
//  ReleaseImagePivot.swift
//  App
//
//  Created by Louis de Beaumont on 14/01/2020.
//

import Foundation
import FluentPostgreSQL

final class ReleaseImagePivot: PostgreSQLUUIDPivot, ModifiablePivot {
  var id: UUID?
  var releaseId: Release.ID
  var imageId: Image.ID
  
  typealias Left = Release
  typealias Right = Image
  
  static var leftIDKey: LeftIDKey {
    return \.releaseId
  }
  
  static var rightIDKey: RightIDKey {
    return \.imageId
  }
  
  init(_ release: Release, _ image: Image) throws {
    self.releaseId = try release.requireID()
    self.imageId = try image.requireID()
  }
}

extension ReleaseImagePivot: Migration {
  static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
    return Database.create(self, on: conn) { (builder) in
      try addProperties(to: builder)
      builder.reference(from: \.releaseId, to: \Release.id, onDelete: .cascade)
      builder.reference(from: \.imageId, to: \Image.id, onDelete: .cascade)
    }
  }
}
