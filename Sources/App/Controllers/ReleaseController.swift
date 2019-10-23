//
//  ReleaseController.swift
//  App
//
//  Created by Louis de Beaumont on 21/10/2019.
//

import Vapor
import Authentication

struct ReleaseController: RouteCollection {
  func boot(router: Router) throws {
    let route = router.grouped("api", "release")
    route.get(use: get)
    route.post(use: create)
    route.post(Release.parameter, "delete", use: delete)
  }
  
  // We aren't populating a release with [ArtistResponse]. This saves lookup time, and stops
  // returning duplicate data. Instead on the mobile side we can lookup an ArtistResponse using
  // the Artist model.
  // Equally we aren't populating ArtistResponse with [Release].
  // TODO: We should apply this reduction across the board.
  func get(_ req: Request) throws -> Future<[ReleaseResponse]> {
    let releases = Release.query(on: req).sort(\Release.date, .ascending).all()
    
    return releases.flatMap { releases -> EventLoopFuture<[ReleaseResponse]> in
      return try releases.map { release -> Future<ReleaseResponse> in
        return try release.artists.query(on: req).all().flatMap { artists -> EventLoopFuture<ReleaseResponse> in
          return Future.map(on: req, { () -> ReleaseResponse in
            return ReleaseResponse(release: release, artists: artists)
          })
        }
      }
      .flatten(on: req)
    }
  }
  
  func create(_ req: Request) throws -> Future<View> {
    let body = req.http.body.description

    guard let data = body.data(using: .utf8) else {
      throw CreateError.runtimeError("Bad request body")
    }

    guard let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, Any> else {
      throw CreateError.runtimeError("Could not arse request body as JSON")
    }
    
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)

    let name = json["name"] as! String
    let date = formatter.date(from: json["date"] as! String)!
    let description = json["description"] as? String
    let imageURL = json["imageURL"] as? String ?? ""
    let spotify = json["spotify"] as? String
    let appleMusic = json["appleMusic"] as? String
    
    let release = Release(name: name,
                          date: date,
                          description: description,
                          imageURL: imageURL,
                          spotify: spotify,
                          appleMusic: appleMusic)
    
    let artists = Artist.query(on: req).all()
    let artistName = json["artist"] as? String

    if json["id"] != nil {
      let id = UUID(uuidString: json["id"] as! String)!
      return artists.flatMap { artists -> EventLoopFuture<View> in
        let artist = artists.filter { artistName == $0.name }.first
        return try self.update(req, id: id, updatedRelease: release, artist: artist!)
      }
    }
    
    return flatMap(artists, release.save(on: req), { (allArtists, release) -> EventLoopFuture<View> in
      let _artist = allArtists.filter { artistName == $0.name }.first

      if let artist = _artist {
        let _ = release.artists.attach(artist, on: req)
      }
      
      let data = ["releases": Release.query(on: req).sort(\Release.date, .ascending).all()]
      return try req.view().render("releaseManagement", data)
    })
  }

  func update(_ req: Request, id: UUID, updatedRelease: Release, artist: Artist) throws -> Future<View> {
    let releaseFuture = Release.find(id, on: req)
    
    return releaseFuture.flatMap { release -> EventLoopFuture<View> in
      release!.name = updatedRelease.name
      release!.date = updatedRelease.date
      release!.description = updatedRelease.description
      release!.imageURL = updatedRelease.imageURL
      release!.spotify = updatedRelease.spotify
      release!.appleMusic = updatedRelease.appleMusic
      
      return flatMap(release!.artists.detachAll(on: req), release!.save(on: req), { (_, event) -> EventLoopFuture<View> in
        let _ = release!.artists.attach(artist, on: req)
        
        let data = ["releases": Release.query(on: req).sort(\Release.date, .ascending).all()]
        return try req.view().render("releaseManagement", data)
      })
    }
  }
  
  func delete(_ req: Request) throws -> Future<Release> {
    let release = try req.parameters.next(Release.self)
    return release.delete(on: req)
  }
}

