//
//  ReleaseController.swift
//  App
//
//  Created by Louis de Beaumont on 21/10/2019.
//

import Vapor
import Fluent

struct ReleaseController: RouteCollection {
  /* AWS
  let awsController: AwsController
  
  init(awsController: AwsController) {
    self.awsController = awsController
  }
  */
  
  func boot(routes: RoutesBuilder) throws {
    let route = routes.grouped("api", "release")
    
    route.get(use: get)
    route.get("latest", use: getLatest)
    
    let auth = route.grouped([
//      User.sessionAuthenticator(),
      RedirectMiddleware(),
    ])
    
    auth.post(use: create)
    auth.post(":releaseID", "delete", use: delete)
  }

  func get(req: Request) -> EventLoopFuture<[ReleaseResponse]> {
    let releasesQuery = Release.query(on: req.db).sort("date", .descending).all()
    
    return releasesQuery.flatMap { releases in
      return releases.map { release in
        let imagesQuery = release.$images.query(on: req.db).first()
        
        return imagesQuery.flatMap { image in
          let image = image ?? Image(url: "", creditText: "", creditLink: "", index: 0)
          let artistsQuery = release.$artists.query(on: req.db).all()
          
          return artistsQuery.flatMap { artists in
            return artists.map { artist in
              return artist.getPreview(db: req.db)
            }
            .flatten(on: req.eventLoop)
            .map { artistPreviews in
              return ReleaseResponse(release: release, artists: artistPreviews, image: image)
            }
          }
        }
      }
      .flatten(on: req.eventLoop)
    }
  }
  
  func getLatest(req: Request) -> EventLoopFuture<ReleaseResponse> {
    Release.query(on: req.db).sort("date", .descending).first()
      .unwrap(or: Abort(.notFound))
      .flatMap { release in
        let imageQuery = release.$images.query(on: req.db).first()
        
        return imageQuery.flatMap { image in
          let image = image ?? Image(url: "", creditText: "", creditLink: "", index: 0)
          let artistsQuery = release.$artists.query(on: req.db).all()
          
          return artistsQuery.flatMap { artists in
            return artists.map { artist in
              return artist.getPreview(db: req.db)
            }
            .flatten(on: req.eventLoop)
            .map { artistPreviews in
              return ReleaseResponse(release: release, artists: artistPreviews, image: image)
            }
          }
        }
      }
  }
  
  func create(req: Request) -> EventLoopFuture<Release> {
    let body = req.body.description

    guard let data = body.data(using: .utf8) else {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Bad request body"))
    }

    let json: Dictionary<String, Any>
    do {
      guard let _json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, Any> else {
        throw CreateError.runtimeError("Could not parse request body as JSON")
      }
      json = _json
    } catch {
      return req.eventLoop.makeFailedFuture(error)
    }
    
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)

    guard let name = json["name"] as? String else {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Invalid release name"))
    }
    
    guard let dateJSON = json["date"] as? String else {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Bad date value"))
    }
    
    guard let date = formatter.date(from: dateJSON) else {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Date value could not be converted to DateTime obejct"))
    }
    
    let description = json["description"] as? String
    let spotify = json["spotify"] as? String
    let appleMusic = json["appleMusic"] as? String
    let googlePlay = json["googlePlay"] as? String
    
    let release = Release(
      name: name,
      date: date,
      description: description,
      spotify: spotify,
      appleMusic: appleMusic,
      googlePlay: googlePlay
    )
    
    let artistsQuery = Artist.query(on: req.db).all()
    
    guard let artistNames = json["artists"] as? [String] else {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("[artists] was not a valid array"))
    }
    
    /* AWS
    guard let uploadedImage = json["image"] as? Dictionary<String, Any> else {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Bad value for image"))
    }
    
    var imageUploadFuture: ImageUploadFuture?
    var image: Image?
    
    if uploadedImage["id"] == nil {
      guard var imageString = uploadedImage["image"] as? String else {
        return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Uploaded image had bad string"))
      }
      
      imageString.replaceOccurances(pattern: "data:image\\/.*;base64,", with: "")
      
      guard let imageData = Data(base64Encoded: imageString) else {
        return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Image string did not convert to data"))
      }
      
      var presignedURL: PresignedURL
      var url: URL
      do {
        presignedUrl = try awsController.preparePresignedUrlForImage(req: req)
        guard let url = URL(string: presignedUrl.url) else {
          throw CreateError.runtimeError("Couldn't create valid URL from S3 URL string")
        }
      } catch {
        return req.eventLoop.makeFailedFuture(error)
      }
      
      var headers = HTTPHeaders()
      headers.add(name: "x-amz-acl", value: "public-read")
      headers.add(name: "Content-Type", value: "text/plain")
      
      let uploadFuture = try req.client.put(url, headers: headers) { put in
        put.body = imageData.convertToHTTPBody()
      }
      
      imageUploadFuture = ImageUploadFuture(uploadFuture: uploadFuture, getUrl: presignedUrl.get, creditText: "", creditLink: "", index: 0)
    }
    
    // messy name uploadFuture when ImageUploadFuture has property uploadFuture
    
    let uploadFuture: EventLoopFuture<Void>
    if let imageUploadFuture = imageUploadFuture {
      uploadFuture = imageUploadFuture.uploadFuture.flatMap { r in
        if (r.status == .ok) {
          image = Image(url: imageUploadFuture.getUrl, creditText: imageUploadFuture.creditText, creditLink: imageUploadFuture.creditLink, index: imageUploadFuture.index)
          if let image = image {
            return image.save(on: req.db)
          }
        }
      }
    }
    */
    
//    return uploadFuture.flatMap { _ in
      if json["id"] != nil {
        guard let _id = json["id"] as? String else {
          return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Bad ID value"))
        }
        
        guard let id = UUID(uuidString: _id) else {
          return req.eventLoop.makeFailedFuture(CreateError.runtimeError("ID was not a valid UUID"))
        }
        
        return artistsQuery.flatMap { artists in
          let artists = artists.filter { artistNames.contains($0.name) }
          return self.update(req: req, id: id, updatedRelease: release, artists: artists) //, image: image)
        }
      }
      
      let releaseSaveRequest = release.save(on: req.db)
      
      return artistsQuery.and(releaseSaveRequest).flatMap { (allArtists, _) in
        /* AWS
        var imageAttachFuture: EventLoopFuture<Void>
        if let image = image {
          imageAttachFuture = release.$images.attach(image, on: req.db).transform(to: ())
        }
        
        return imageAttachFuture.flatMap { _ -> EventLoopFuture<Release> in */
          let artists = allArtists.filter { artistNames.contains($0.name) }
          
          return artists.map { artist in
            return release.$artists.attach(artist, on: req.db)
          }
          .flatten(on: req.eventLoop)
          .transform(to: release)
//        }
//      }
    }
  }

  func update(req: Request, id: UUID, updatedRelease: Release, artists: [Artist]) -> EventLoopFuture<Release> { //, image: Image?) -> EventLoopFuture<Release> {
    Release.find(id, on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { release in
        release.name = updatedRelease.name
        release.date = updatedRelease.date
        release.description = updatedRelease.description
        release.spotify = updatedRelease.spotify
        release.appleMusic = updatedRelease.appleMusic
        release.googlePlay = updatedRelease.googlePlay
        
        /* AWS
        var imageUpdateFuture: EventLoopFuture<Void>
        if let image = image {
          imageUpdateFuture = release.$images.detach(image, on: req.db).flatMap { _ in // What are we detaching?
            return release.$images.attach(image, on: req.db)
          }.transform(to: ())
        }
        */
        
        let artistsDetachRequest = release.$artists.detach(artists, on: req.db)
        let releaseSaveRequest = release.save(on: req.db)
        
        return artistsDetachRequest.and(releaseSaveRequest).flatMap { _ in // imageUpdateFuture.and
          return artists.map { artist in
            return release.$artists.attach(artist, on: req.db)
          }
          .flatten(on: req.eventLoop)
          .transform(to: release)
        }
      }
  }
  
  func delete(req: Request) -> EventLoopFuture<Release> {
    Release.find(req.parameters.get("release"), on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { release in
        return release.delete(on: req.db).transform(to: release)
      }
  }
}
