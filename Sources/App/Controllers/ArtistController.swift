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
    return artist.save(on: req)
  }
  
  func get(_ req: Request) throws -> Future<[Artist]> {
    return Artist.query(on: req).all()
  }
}
