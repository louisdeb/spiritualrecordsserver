//
//  Image.swift
//  App
//
//  Created by Louis de Beaumont on 21/12/2019.
//

import Fluent
import Vapor

final class Image: Model {
  static let schema = "images"
  
  @ID(key: .id)
  var id: UUID?
  
  @Field(key: "url")
  var url: String
  
  @Field(key: "creditText")
  var creditText: String
  
  @Field(key: "creditLink")
  var creditLink: String
  
  @Field(key: "index")
  var index: Int
  
  @Siblings(through: ArtistImage.self, from: \.$image, to: \.$artist)
  var artists: [Artist]
  
  init() {}
  
  init(url: String, creditText: String?, creditLink: String?, index: Int) {
    self.url = url
    self.creditText = creditText ?? ""
    self.creditLink = creditLink ?? ""
    self.index = index
  }
}

extension Image {
  struct Create: Migration {
    let name = Image.schema
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
      database.schema(name)
        .field("id", .uuid, .identifier(auto: true))
        .field("url", .uuid, .required)
        .field("creditText", .uuid, .required)
        .field("creditLink", .uuid, .required)
        .field("index", .uuid, .required)
        .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
      database.schema(name).delete()
    }
  }
}

extension Image: Content {}

struct ImageUploadFuture {
  var uploadFuture: EventLoopFuture<Response>
  var getUrl: String
  var creditText: String?
  var creditLink: String?
  var index: Int
}

struct ImageUpdateInformation {
  var id: UUID
  var creditText: String?
  var creditLink: String?
  var index: Int
}
