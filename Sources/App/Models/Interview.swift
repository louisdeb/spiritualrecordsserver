//
//  Interview.swift
//  App
//
//  Created by Louis de Beaumont on 31/10/2019.
//

import Fluent
import Vapor

final class Interview: Model {
  static let schema = "interviews"
  
  @ID(key: .id)
  var id: UUID?
  
  @Field(key: "name")
  var name: String
  
  @Field(key: "date")
  var date: Date
  
  @Field(key: "shortDescription")
  var shortDescription: String
  
  @Field(key: "description")
  var description: String
  
  @Field(key: "imageURL")
  var imageURL: String
  
  @Field(key: "videoURL")
  var videoURL: String
  
  @Siblings(through: ArtistInterview.self, from: \.$interview, to: \.$artist)
  var artists: [Artist]
  
  init() {}
  
  init(name: String, date: Date, shortDescription: String?,
       description: String?, imageURL: String?, videoURL: String?) {
    self.name = name
    self.date = date
    self.shortDescription = shortDescription ?? ""
    self.description = description ?? ""
    self.imageURL = imageURL ?? ""
    self.videoURL = videoURL ?? ""
  }
}

extension Interview {
 struct Create: Migration {
    let name = Interview.schema
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
      database.schema(name)
        .field("id", .uuid, .identifier(auto: true))
        .field("name", .uuid, .required)
        .field("date", .uuid, .required)
        .field("shortDescription", .uuid, .required)
        .field("description", .uuid, .required)
        .field("imageURL", .uuid, .required)
        .field("videoURL", .uuid, .required)
        .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
      database.schema(name).delete()
    }
  }
}

extension Interview: Content {}
