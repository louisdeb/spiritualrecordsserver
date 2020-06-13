//
//  Artist.swift
//  App
//
//  Created by Louis de Beaumont on 01/09/2019.
//

import Fluent
import Vapor

final class Artist: Model {
  static let schema = "Artist"
  
  @ID(key: .id)
  var id: UUID?
  
  @Field(key: "name")
  var name: String
  
  @Field(key: "shortDescription")
  var shortDescription: String
  
  @Field(key: "description")
  var description: String
  
  @Field(key: "spotify")
  var spotify: String
  
  @Field(key: "appleMusic")
  var appleMusic: String
  
  @Field(key: "googlePlay")
  var googlePlay: String
  
  @Field(key: "instagram")
  var instagram: String
  
  @Field(key: "facebook")
  var facebook: String
  
  @Field(key: "website")
  var website: String
  
  @Siblings(through: ArtistImage.self, from: \.$artist, to: \.$image)
  var images: [Image]
  
  @Siblings(through: ArtistEvent.self, from: \.$artist, to: \.$event)
  var events: [Event]
  
  @Siblings(through: ArtistRelease.self, from: \.$artist, to: \.$release)
  var releases: [Release]
  
  init() {}
  
  init(name: String, shortDescription: String?, description: String?,
       spotify: String?, appleMusic: String?, googlePlay: String?,
       instagram: String?, facebook: String?, website: String?) {
    self.name = name
    self.shortDescription = shortDescription ?? ""
    self.description = description ?? ""
    self.spotify = spotify ?? ""
    self.appleMusic = appleMusic ?? ""
    self.googlePlay = googlePlay ?? ""
    self.instagram = instagram ?? ""
    self.facebook = facebook ?? ""
    self.website = website ?? ""
  }
  
  final class Preview: Model {
    static let schema = "artist.preview"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "shortDescription")
    var shortDescription: String
    
    @Field(key: "imageURL")
    var imageURL: String
    
    init() {}
    
    init(id: UUID?, name: String, shortDescription: String, imageURL: String) {
      self.id = id
      self.name = name
      self.shortDescription = shortDescription
      self.imageURL = imageURL
    }
  }
  
  final class Profile: Model {
    static let schema = "artist.profile"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "artist")
    var artist: Artist
    
    @Field(key: "images")
    var images: [Image]
    
    init() {}
    
    init(artist: Artist, images: [Image]) {
      self.id = artist.id
      self.artist = artist
      self.images = images
    }
  }
}

extension Artist {
  struct Create: Migration {
    let name = Artist.schema
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
      database.schema(name)
        .field("id", .uuid, .identifier(auto: true))
        .field("name", .uuid, .required)
        .field("shortDescription", .uuid, .required)
        .field("description", .uuid, .required)
        .field("spotify", .uuid, .required)
        .field("appleMusic", .uuid, .required)
        .field("googlePlay", .uuid, .required)
        .field("instagram", .uuid, .required)
        .field("facebook", .uuid, .required)
        .field("website", .uuid, .required)
        .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
      database.schema(name).delete()
    }
  }
}

extension Artist: Content {}

extension Artist.Preview: Content {}
extension Artist.Profile: Content {}

extension Artist {
  func getPreview(db: Database) -> EventLoopFuture<Artist.Preview> {
    let imageQuery = $images.query(on: db).sort("index", .ascending).first()
    return imageQuery.map { image in
      let imageURL = image?.url ?? ""
      return Artist.Preview(id: self.id, name: self.name, shortDescription: self.shortDescription, imageURL: imageURL)
    }
  }
}

extension Artist {
  func getProfile(db: Database) -> EventLoopFuture<Artist.Profile> {
    let imagesQuery = $images.query(on: db).sort("index", .ascending).all()
    return imagesQuery.map { images in
      return Artist.Profile(artist: self, images: images)
    }
  }
}
