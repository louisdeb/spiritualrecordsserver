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
    route.get(Artist.parameter, use: getResponse)
    
    let sessionMiddleware = User.authSessionsMiddleware()
    let redirectMiddleware = RedirectMiddleware(A: User.self, path: "/login")
    let auth = route.grouped(sessionMiddleware, redirectMiddleware)
    
    auth.post(use: create)
    auth.post(Artist.parameter, "delete", use: delete)
  }
  
  func get(_ req: Request) throws -> Future<[Artist.Preview]> {
    let artists = Artist.query(on: req).sort(\Artist.name, .ascending).all()
    return artists.flatMap { artists -> EventLoopFuture<[Artist.Preview]> in
      return artists.map { artist -> EventLoopFuture<Artist.Preview> in
        return Future.map(on: req, { () -> Artist.Preview in
          return artist.getPreview()
        })
      }
      .flatten(on: req)
    }
  }
  
  func getResponse(_ req: Request) throws -> Future<ArtistResponse> {
    let artist = try req.parameters.next(Artist.self)
    
    return artist.flatMap { artist -> EventLoopFuture<ArtistResponse> in
      return try artist.events.query(on: req).all().flatMap { allEvents -> EventLoopFuture<ArtistResponse> in
        let events = allEvents.filter { $0.isUpcoming() }
        
        return try artist.releases.query(on: req).all().flatMap { releases -> EventLoopFuture<ArtistResponse> in
          return Future.map(on: req, { () -> ArtistResponse in
            return ArtistResponse(artist: artist, events: events, releases: releases)
          })
        }
      }
    }
  }
  
  func create(_ req: Request) throws -> Future<View> {
    let body = req.http.body.description
    
    guard let data = body.data(using: .utf8) else {
      throw CreateError.runtimeError("Bad request body")
    }
    
    guard let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, Any> else {
      throw CreateError.runtimeError("Could not parse request body as JSON")
    }
    
    guard let name = json["name"] as? String else {
      throw CreateError.runtimeError("Invalid artist name")
    }
    
    let shortDescription = json["shortDescription"] as? String
    let description = json["description"] as? String
    
    guard let imageURLs = json["imageURLs"] as? [String] else {
      throw CreateError.runtimeError("Invalid [imageURL]")
    }
    
    guard !imageURLs.isEmpty else {
      throw CreateError.runtimeError("No image URLs were provided")
    }
    
    let spotify = json["spotify"] as? String
    let appleMusic = json["appleMusic"] as? String
    let googlePlay = json["googlePlay"] as? String
    let instagram = json["instagram"] as? String
    let facebook = json["facebook"] as? String
    let website = json["website"] as? String
    
    let artist = Artist(name: name,
                        shortDescription: shortDescription,
                        description: description,
                        imageURLs: imageURLs,
                        spotify: spotify,
                        appleMusic: appleMusic,
                        googlePlay: googlePlay,
                        instagram: instagram,
                        facebook: facebook,
                        website: website)
    
    if json["id"] != nil {
      guard let _id = json["id"] as? String else {
        throw CreateError.runtimeError("Bad id value")
      }
      
      guard let id = UUID(uuidString: _id) else {
        throw CreateError.runtimeError("Id was not a valid UUID")
      }
      
      return try update(req, id: id, updatedArtist: artist)
    }
    
    return artist.save(on: req).flatMap { artist -> EventLoopFuture<View> in
      let data = ["artists": Artist.query(on: req).sort(\Artist.name, .ascending).all()]
      return try req.view().render("artistManagement", data)
    }
  }
  
  func update(_ req: Request, id: UUID, updatedArtist: Artist) throws -> Future<View> {
    let artistFuture = Artist.find(id, on: req)
    
    return artistFuture.flatMap { artist_ -> EventLoopFuture<View> in
      guard let artist = artist_ else {
        throw CreateError.runtimeError("Could not find artist to update")
      }
      
      artist.name = updatedArtist.name
      artist.shortDescription = updatedArtist.shortDescription
      artist.description = updatedArtist.description
      artist.imageURLs = updatedArtist.imageURLs
      artist.website = updatedArtist.website
      artist.spotify = updatedArtist.spotify
      artist.appleMusic = updatedArtist.appleMusic
      artist.googlePlay = updatedArtist.googlePlay
      artist.instagram = updatedArtist.instagram
      artist.facebook = updatedArtist.facebook
      
      return artist.save(on: req).flatMap { artist -> EventLoopFuture<View> in
        let data = ["artists": Artist.query(on: req).sort(\Artist.name, .ascending).all()]
        return try req.view().render("artistManagement", data)
      }
    }
  }
  
  func delete(_ req: Request) throws -> EventLoopFuture<[Release]> {
    let artist = try req.parameters.next(Artist.self)
    
    
    
    return artist.flatMap { artist -> EventLoopFuture<[Release]> in
      let releases = try artist.releases.query(on: req).all()
      
      return flatMap(releases, artist.delete(on: req), { (releases, _) -> EventLoopFuture<[Release]> in
        return try releases.map { release -> EventLoopFuture<Release> in
          return try release.artists.query(on: req).all().flatMap { artists -> EventLoopFuture<Release> in
            if (artists.isEmpty) {
              return release.delete(on: req).transform(to: release)
            }
            
            return Future.map(on: req, { () -> Release in
              return release
            })
          }
        }
        .flatten(on: req)
      })
    }
  }
}
