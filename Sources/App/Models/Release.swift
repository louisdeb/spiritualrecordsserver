//
//  Release.swift
//  App
//
//  Created by Louis de Beaumont on 21/10/2019.
//

import Vapor
import Fluent

final class Release: Model {
  static let schema = "releases"
  
  @ID(key: .id)
  var id: UUID?
  
  @Field(key: "name")
  var name: String
  
  @Field(key: "date")
  var date: Date
  
  @Field(key: "description")
  var description: String
  
  @Field(key: "spotify")
  var spotify: String
  
  @Field(key: "appleMusic")
  var appleMusic: String
  
  @Field(key: "googlePlay")
  var googlePlay: String
  
  @Siblings(through: ArtistRelease.self, from: \.$release, to: \.$artist)
  var artists: [Artist]
  
  @Siblings(through: ReleaseImage.self, from: \.$release, to : \.$image)
  var images: [Image]
  
  init() {}
  
  init(name: String, date: Date, description: String?,
       spotify: String?, appleMusic: String?, googlePlay: String?) {
    self.name = name
    self.date = date
    self.description = description ?? ""
    self.spotify = spotify ?? ""
    self.appleMusic = appleMusic ?? ""
    self.googlePlay = googlePlay ?? ""
  } 
}

extension Release {
  struct Create: Migration {
    let name = Release.schema
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
      database.schema(name)
        .field("id", .uuid, .identifier(auto: true))
        .field("name", .uuid, .required)
        .field("date", .uuid, .required)
        .field("description", .uuid, .required)
        .field("spotify", .uuid, .required)
        .field("appleMusic", .uuid, .required)
        .field("googlePlay", .uuid, .required)
        .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
      database.schema(name).delete()
    }
  }
}

extension Release: Content {}
