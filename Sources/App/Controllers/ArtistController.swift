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
    route.post(Artist.self, use: create)
    route.get(use: get)
  }
  
  func create(_ req: Request, artist: Artist) throws -> Future<Artist> {
    if artist.id != nil {
      return try update(req, updatedArtist: artist)
    }
    return artist.save(on: req)
  }
  
  func get(_ req: Request) throws -> Future<[Artist]> {
    return Artist.query(on: req).sort(\Artist.name, .descending).all()
  }
  
  func update(_ req: Request, updatedArtist: Artist) throws -> Future<Artist> {
    let artistFuture = Artist.find(updatedArtist.id!, on: req)
    return artistFuture.flatMap { (artist) -> EventLoopFuture<Artist> in
      artist!.name = updatedArtist.name
      artist!.description = updatedArtist.description
      artist!.image = updatedArtist.image
      artist!.website = updatedArtist.website
      artist!.spotify = updatedArtist.spotify
      artist!.instagram = updatedArtist.instagram
      artist!.facebook = updatedArtist.facebook
      return artist!.save(on: req)
    }
  }
}
