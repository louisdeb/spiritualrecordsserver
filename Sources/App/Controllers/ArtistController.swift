//
//  ArtistController.swift
//  App
//
//  Created by Louis de Beaumont on 02/09/2019.
//

import Vapor
import Authentication

struct ArtistController: RouteCollection {
  func boot(router: Router) throws {
    let route = router.grouped("api", "artist")
    route.get(use: get)
    route.get(Artist.parameter, "events", use: getEvents)
    route.post(Artist.self, use: create)
    route.post(Artist.parameter, "delete", use: delete)
  }
  
  func get(_ req: Request) throws -> Future<[Artist]> {
    return Artist.query(on: req).sort(\Artist.name, .ascending).all()
  }
  
  // Does not filter for upcoming events
  func getEvents(_ req: Request) throws -> Future<[Event]> {
    let artistFuture = try req.parameters.next(Artist.self)
    return artistFuture.flatMap(to: [Event].self) { (artist) in
      return try artist.events.query(on: req).all()
    }
  }
  
  func create(_ req: Request, artist: Artist) throws -> Future<View> {
    if artist.id != nil {
      return try update(req, updatedArtist: artist)
    }
    
    return artist.save(on: req).flatMap { artist -> EventLoopFuture<View> in
      let data = ["artists": Artist.query(on: req).sort(\Artist.name, .ascending).all()]
      return try req.view().render("artistManagement", data)
    }
  }
  
  func update(_ req: Request, updatedArtist: Artist) throws -> Future<View> {
    let artistFuture = Artist.find(updatedArtist.id!, on: req)
    
    return artistFuture.flatMap { artist -> EventLoopFuture<View> in
      artist!.name = updatedArtist.name
      artist!.description = updatedArtist.description
      artist!.imageURL = updatedArtist.imageURL
      artist!.website = updatedArtist.website
      artist!.spotify = updatedArtist.spotify
      artist!.instagram = updatedArtist.instagram
      artist!.facebook = updatedArtist.facebook
      
      return artist!.save(on: req).flatMap { artist -> EventLoopFuture<View> in
        let data = ["artists": Artist.query(on: req).sort(\Artist.name, .ascending).all()]
        return try req.view().render("artistManagement", data)
      }
    }
  }
  
  func delete(_ req: Request) throws -> Future<Artist> {
    let artist = try req.parameters.next(Artist.self)
    return artist.delete(on: req)
  }
}
