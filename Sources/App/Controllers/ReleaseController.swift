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
          return Future.map(on: req, { () -> ReleaseResponse in
            return ReleaseResponse(release: release, artists: artists)
          })
        }
      }
      .flatten(on: req)
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

    let name = json["name"] as! String
    let date = formatter.date(from: json["date"] as! String)!
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
    let artistNames = json["artists"] as! [String]

    if json["id"] != nil {
      let id = UUID(uuidString: json["id"] as! String)!
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

