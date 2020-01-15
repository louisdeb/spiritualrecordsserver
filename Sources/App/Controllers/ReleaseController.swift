//
//  ReleaseController.swift
//  App
//
//  Created by Louis de Beaumont on 21/10/2019.
//

import Vapor
import Authentication

struct ReleaseController: RouteCollection {
  private let awsController: AwsController
  
  init(awsController: AwsController) {
    self.awsController = awsController
  }
  
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
        return try release.images.query(on: req).first().flatMap { image_ -> EventLoopFuture<ReleaseResponse> in
          let image = image_ ?? Image(url: release.imageURL, creditText: "", creditLink: "")
          
          return try release.artists.query(on: req).all().flatMap { artists -> EventLoopFuture<ReleaseResponse> in
            return try artists.map { artist -> EventLoopFuture<Artist.Preview> in
              return try artist.getPreview(req)
            }
            .flatten(on: req)
            .flatMap { artistPreviews -> EventLoopFuture<ReleaseResponse> in
              return Future.map(on: req, { () -> ReleaseResponse in
                return ReleaseResponse(release: release, artists: artistPreviews, image: image)
              })
            }
          }
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
      
      return try release.images.query(on: req).first().flatMap { image_ -> EventLoopFuture<ReleaseResponse> in
        let image = image_ ?? Image(url: release.imageURL, creditText: "", creditLink: "")
        
        return try release.artists.query(on: req).all().flatMap { artists -> EventLoopFuture<ReleaseResponse> in
          return try artists.map { artist -> EventLoopFuture<Artist.Preview> in
            return try artist.getPreview(req)
          }
          .flatten(on: req)
          .flatMap { artistPreviews -> EventLoopFuture<ReleaseResponse> in
            return Future.map(on: req, { () -> ReleaseResponse in
              return ReleaseResponse(release: release, artists: artistPreviews, image: image)
            })
          }
        }
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
    let spotify = json["spotify"] as? String
    let appleMusic = json["appleMusic"] as? String
    let googlePlay = json["googlePlay"] as? String
    
    let release = Release(name: name,
                          date: date,
                          description: description,
                          spotify: spotify,
                          appleMusic: appleMusic,
                          googlePlay: googlePlay)
    
    let artists = Artist.query(on: req).all()
    
    guard let artistNames = json["artists"] as? [String] else {
      throw CreateError.runtimeError("[artists] was not a valid array")
    }
    
    guard let uploadedImage = json["image"] as? Dictionary<String, Any> else {
      throw CreateError.runtimeError("Bad value for image")
    }
    
    var imageUploadFuture: ImageUploadFuture?
    var image: Image?
    
    if uploadedImage["id"] == nil {
      guard var imageString = uploadedImage["image"] as? String else {
        throw CreateError.runtimeError("Uploaded image had bad string")
      }
      
      imageString.replaceOccurances(pattern: "data:image\\/.*;base64,", with: "")
      
      guard let imageData = Data(base64Encoded: imageString) else {
        throw CreateError.runtimeError("Image string did not convert to data")
      }
      
      let presignedUrl = try awsController.preparePresignedUrlForImage(req: req)
      guard let url = URL(string: presignedUrl.url) else {
        throw CreateError.runtimeError("Couldn't create valid URL from S3 URL string")
      }
      
      var headers = HTTPHeaders()
      headers.add(name: "x-amz-acl", value: "public-read")
      headers.add(name: "Content-Type", value: "text/plain")
      
      let uploadFuture = try req.client().put(url, headers: headers) { put in
        put.http.body = imageData.convertToHTTPBody()
      }
      
      imageUploadFuture = ImageUploadFuture(uploadFuture: uploadFuture, getUrl: presignedUrl.get, creditText: "", creditLink: "")
    }
    
    let uploadFuture = imageUploadFuture != nil ? imageUploadFuture!.uploadFuture.flatMap { r -> EventLoopFuture<Void> in
      if (r.http.status == .ok) {
        image = Image(url: imageUploadFuture!.getUrl, creditText: imageUploadFuture!.creditText, creditLink: imageUploadFuture!.creditLink)
        return image!.save(on: req).transform(to: ())
      }
      return Future.map(on: req, { () -> Void in return })
    } : Future.map(on: req, { () -> Void in return })
    
    return uploadFuture.flatMap { _ -> EventLoopFuture<Release> in
      if json["id"] != nil {
        guard let _id = json["id"] as? String else {
          throw CreateError.runtimeError("Bad id value")
        }
        
        guard let id = UUID(uuidString: _id) else {
          throw CreateError.runtimeError("Id was not a valid UUID")
        }
        
        return artists.flatMap { artists -> EventLoopFuture<Release> in
          let artists = artists.filter { artistNames.contains($0.name) }
          return try self.update(req, id: id, updatedRelease: release, artists: artists, image: image)
        }
      }
      
      return flatMap(artists, release.save(on: req), { (allArtists, release) -> EventLoopFuture<Release> in
        var imageAttachFuture = Future.map(on: req, { () -> Void in return })
        if image != nil {
          imageAttachFuture = release.images.attach(image!, on: req).transform(to: ())
        }
        
        return imageAttachFuture.flatMap { _ -> EventLoopFuture<Release> in
          let artists = allArtists.filter { artistNames.contains($0.name) }
          
          return artists.map { artist in
            return release.artists.attach(artist, on: req)
          }
          .flatten(on: req)
          .transform(to: release)
        }
      })
    }
  }

  func update(_ req: Request, id: UUID, updatedRelease: Release, artists: [Artist], image: Image?) throws -> Future<Release> {
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
      
      var imageUpdateFuture = Future.map(on: req, { () -> Void in return })
      if image != nil {
        imageUpdateFuture = release.images.detachAll(on: req).flatMap { _ -> EventLoopFuture<ReleaseImagePivot> in
          return release.images.attach(image!, on: req)
        }.transform(to: ())
      }
      
      return flatMap(imageUpdateFuture, release.artists.detachAll(on: req), release.save(on: req), { (_, _, release) -> EventLoopFuture<Release> in
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

