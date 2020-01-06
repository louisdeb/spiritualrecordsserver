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
    route.get("latest", use: getLatest)
    
    let sessionMiddleware = User.authSessionsMiddleware()
    let redirectMiddleware = RedirectMiddleware(A: User.self, path: "/login")
    let auth = route.grouped(sessionMiddleware, redirectMiddleware)
    
    auth.post(use: create)
    auth.post(Release.parameter, "delete", use: delete)
  }

  func get(_ req: Request) throws -> Future<[ReleaseResponse]> {
    let releases = Release.query(on: req).sort(\Release.date, .descending).all()
    
    return releases.flatMap { releases -> EventLoopFuture<[ReleaseResponse]> in
      return try releases.map { release -> Future<ReleaseResponse> in
        return try release.artists.query(on: req).all().flatMap { artists -> EventLoopFuture<ReleaseResponse> in
          let artistPreviews = try artists.map { artist -> Artist.Preview in
            return try artist.getPreview(req).wait()
          }
          return Future.map(on: req, { () -> ReleaseResponse in
            return ReleaseResponse(release: release, artists: artistPreviews)
          })
        }
      }
      .flatten(on: req)
    }
  }
  
  func getLatest(_ req: Request) throws -> Future<ReleaseResponse> {
    let release = Release.query(on: req).sort(\Release.date, .descending).first()
    
    return release.flatMap { release_ -> EventLoopFuture<ReleaseResponse> in
      guard let release = release_ else {
        throw GetError.runtimeError("No releases")
      }
      
      return try release.artists.query(on: req).all().flatMap { artists -> EventLoopFuture<ReleaseResponse> in
        let artistPreviews = try artists.map { artist -> Artist.Preview in
          return try artist.getPreview(req).wait()
        }
        return Future.map(on: req, { () -> ReleaseResponse in
          return ReleaseResponse(release: release, artists: artistPreviews)
        })
      }
    }
  }
  
  func create(_ req: Request) throws -> Future<Release> {
    let body = req.http.body.description

    guard let data = body.data(using: .utf8) else {
      throw CreateError.runtimeError("Bad request body")
    }

    guard let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, Any> else {
      throw CreateError.runtimeError("Could not parse request body as JSON")
    }
    
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)

    guard let name = json["name"] as? String else {
      throw CreateError.runtimeError("Invalid release name")
    }
    
    guard let dateJSON = json["date"] as? String else {
      throw CreateError.runtimeError("Bad date value")
    }

    guard let date = formatter.date(from: dateJSON) else {
      throw CreateError.runtimeError("Date value could not be converted to DateTime obejct")
    }
    
    let description = json["description"] as? String
    let imageURL = json["imageURL"] as? String ?? ""
    let spotify = json["spotify"] as? String
    let appleMusic = json["appleMusic"] as? String
    let googlePlay = json["googlePlay"] as? String
    
    let release = Release(name: name,
                          date: date,
                          description: description,
                          imageURL: imageURL,
                          spotify: spotify,
                          appleMusic: appleMusic,
                          googlePlay: googlePlay)
    
    let artists = Artist.query(on: req).all()
    
    guard let artistNames = json["artists"] as? [String] else {
      throw CreateError.runtimeError("[artists] was not a valid array")
    }

    if json["id"] != nil {
      guard let _id = json["id"] as? String else {
        throw CreateError.runtimeError("Bad id value")
      }
      
      guard let id = UUID(uuidString: _id) else {
        throw CreateError.runtimeError("Id was not a valid UUID")
      }
      
      return artists.flatMap { artists -> EventLoopFuture<Release> in
        let artists = artists.filter { artistNames.contains($0.name) }
        return try self.update(req, id: id, updatedRelease: release, artists: artists)
      }
    }
    
    return flatMap(artists, release.save(on: req), { (allArtists, release) -> EventLoopFuture<Release> in
      let artists = allArtists.filter { artistNames.contains($0.name) }
      
      return artists.map { artist in
        return release.artists.attach(artist, on: req)
      }
      .flatten(on: req)
      .transform(to: release)
    })
  }

  func update(_ req: Request, id: UUID, updatedRelease: Release, artists: [Artist]) throws -> Future<Release> {
    let releaseFuture = Release.find(id, on: req)
    
    return releaseFuture.flatMap { release_ -> EventLoopFuture<Release> in
      guard let release = release_ else {
        throw CreateError.runtimeError("Could not find release to update")
      }
      
      release.name = updatedRelease.name
      release.date = updatedRelease.date
      release.description = updatedRelease.description
      release.imageURL = updatedRelease.imageURL
      release.spotify = updatedRelease.spotify
      release.appleMusic = updatedRelease.appleMusic
      release.googlePlay = updatedRelease.googlePlay
      
      return flatMap(release.artists.detachAll(on: req), release.save(on: req), { (_, release) -> EventLoopFuture<Release> in
        return artists.map { artist in
          return release.artists.attach(artist, on: req)
        }
        .flatten(on: req)
        .transform(to: release)
      })
    }
  }
  
  func delete(_ req: Request) throws -> Future<Release> {
    let release = try req.parameters.next(Release.self)
    return release.delete(on: req)
  }
}

