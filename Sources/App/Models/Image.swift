//
//  Image.swift
//  App
//
//  Created by Louis de Beaumont on 21/12/2019.
//

import FluentPostgreSQL
import Vapor
import struct S3.File

final class Image: Codable {
  var id: UUID?
  
  var url: String
  var creditText: String
  var creditLink: String
  
  init(url: String, creditText: String?, creditLink: String?) {
    self.url = url
    self.creditText = creditText ?? ""
    self.creditLink = creditLink ?? ""
  }
}

extension Image {
  var artists: Siblings<Image, Artist, ArtistImagePivot> {
    return siblings()
  }
}

extension Image: Migration {
  static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
    return Database.create(self, on: connection) { builder in
      try addProperties(to: builder)
      builder.unique(on: \.id)
    }
  }
}

extension Image: PostgreSQLUUIDModel {}
extension Image: Content {}
extension Image: Parameter {}

struct ImageUploadFuture {
  var uploadFuture: EventLoopFuture<Response>
  var getUrl: String
  var creditText: String?
  var creditLink: String?
}
