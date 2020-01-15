//
//  ArtistController.swift
//  App
//
//  Created by Louis de Beaumont on 02/09/2019.
//

import Vapor
import Authentication
import S3
import struct S3.File

struct ArtistController: RouteCollection {
  private let awsController: AwsController
  
  init(awsController: AwsController) {
    self.awsController = awsController
  }
  
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
      return try artists.map { artist -> EventLoopFuture<Artist.Preview> in
        return try artist.getPreview(req)
      }
      .flatten(on: req)
    }
  }
  
  func getResponse(_ req: Request) throws -> Future<ArtistResponse> {
    let artist = try req.parameters.next(Artist.self)
    
    return artist.flatMap { artist -> EventLoopFuture<ArtistResponse> in
      return try artist.images.query(on: req).sort(\Image.index, .ascending).all().flatMap { images -> EventLoopFuture<ArtistResponse> in
        return try artist.events.query(on: req).sort(\Event.date, .ascending).all().flatMap { allEvents -> EventLoopFuture<ArtistResponse> in
          let events = allEvents.filter { $0.isUpcoming() }
          return try artist.releases.query(on: req).all().flatMap { releases -> EventLoopFuture<ArtistResponse> in
            return Future.map(on: req, { () -> ArtistResponse in
              return ArtistResponse(artist: artist, images: images, events: events, releases: releases)
            })
          }
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
    
    let spotify = json["spotify"] as? String
    let appleMusic = json["appleMusic"] as? String
    let googlePlay = json["googlePlay"] as? String
    let instagram = json["instagram"] as? String
    let facebook = json["facebook"] as? String
    let website = json["website"] as? String
    
    let artist = Artist(name: name,
                        shortDescription: shortDescription,
                        description: description,
                        spotify: spotify,
                        appleMusic: appleMusic,
                        googlePlay: googlePlay,
                        instagram: instagram,
                        facebook: facebook,
                        website: website)
    
    guard let uploadedImages = json["images"] as? [Dictionary<String, Any>] else {
      throw CreateError.runtimeError("Bad value for images")
    }
    
    guard !uploadedImages.isEmpty else {
      throw CreateError.runtimeError("No images were provided")
    }
    
    var imageUploadFutures: [ImageUploadFuture] = []
    var updatedImages: [ImageUpdateInformation] = []
    
    for (_, imageJson) in uploadedImages.enumerated() {
      let creditText = imageJson["creditText"] as? String
      let creditLink = imageJson["creditLink"] as? String
      
      let indexString = imageJson["index"] as? String
      var index = 0
      if indexString != nil, let indexInt = Int(indexString!) {
        index = indexInt
      }
      
      if imageJson["id"] != nil {
        guard let _id = imageJson["id"] as? String else {
          throw CreateError.runtimeError("Bad image id value")
        }
        
        guard let uuid = UUID(uuidString: _id) else {
          throw CreateError.runtimeError("Image id was not a valid UUID")
        }
        
        updatedImages.append(ImageUpdateInformation(id: uuid, creditText: creditText, creditLink: creditLink, index: index))
        continue
      }
      
      guard var imageString = imageJson["image"] as? String else {
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
      
      imageUploadFutures.append(ImageUploadFuture(uploadFuture: uploadFuture, getUrl: presignedUrl.get, creditText: creditText, creditLink: creditLink, index: index))
    }
    
    var images: [Image] = []
    
    let allImagesUploadFuture: EventLoopFuture<Void> = imageUploadFutures.map { imageUploadFuture -> EventLoopFuture<Void> in
      return imageUploadFuture.uploadFuture.flatMap { r -> EventLoopFuture<Void> in
        if (r.http.status == .ok) {
          let image = Image(url: imageUploadFuture.getUrl, creditText: imageUploadFuture.creditText, creditLink: imageUploadFuture.creditLink, index: imageUploadFuture.index)
          images.append(image)
          return image.save(on: req).transform(to: ())
        }
        return Future.map(on: req, { () -> Void in return })
      }
    }.flatten(on: req)
    
    return allImagesUploadFuture.flatMap { r -> EventLoopFuture<View> in
      if json["id"] != nil {
        guard let _id = json["id"] as? String else {
          throw CreateError.runtimeError("Bad id value")
        }
        
        guard let id = UUID(uuidString: _id) else {
          throw CreateError.runtimeError("Id was not a valid UUID")
        }
        
        return try self.update(req, id: id, updatedArtist: artist, newImages: images, updatedImages: updatedImages)
      }
      
      return artist.save(on: req).flatMap { artist -> EventLoopFuture<View> in
        return images.map { image in
          return artist.images.attach(image, on: req)
        }
        .flatten(on: req)
        .transform(to: artist).flatMap { artist -> EventLoopFuture<View> in
          let data = ["artists": Artist.query(on: req).sort(\Artist.name, .ascending).all()]
          return try req.view().render("artistManagement", data)
        }
      }
    }
  }
  
  func update(_ req: Request, id: UUID, updatedArtist: Artist, newImages: [Image], updatedImages: [ImageUpdateInformation]) throws -> Future<View> {
    let artistFuture = Artist.find(id, on: req)
    
    return artistFuture.flatMap { artist_ -> EventLoopFuture<View> in
      guard let artist = artist_ else {
        throw CreateError.runtimeError("Could not find artist to update")
      }
      
      artist.name = updatedArtist.name
      artist.shortDescription = updatedArtist.shortDescription
      artist.description = updatedArtist.description
      artist.website = updatedArtist.website
      artist.spotify = updatedArtist.spotify
      artist.appleMusic = updatedArtist.appleMusic
      artist.googlePlay = updatedArtist.googlePlay
      artist.instagram = updatedArtist.instagram
      artist.facebook = updatedArtist.facebook
      
      return artist.save(on: req).flatMap { artist -> EventLoopFuture<View> in
        return try artist.images.query(on: req).all().flatMap { images -> EventLoopFuture<View> in
          return images.map { image in
            let matches = updatedImages.filter { $0.id == image.id! }
            if (matches.isEmpty) {
              return artist.images.detach(image, on: req).flatMap { _ -> EventLoopFuture<Void> in
                return try image.artists.query(on: req).count().flatMap { numberOfArtists -> EventLoopFuture<Void> in
                  return numberOfArtists == 0 ? image.delete(on: req) : Future.map(on: req) { () -> Void in }
                }
              }
            }
            let updatedImage = matches.first!
            image.creditText = updatedImage.creditText ?? ""
            image.creditLink = updatedImage.creditLink ?? ""
            image.index = updatedImage.index
            return image.save(on: req).transform(to: ())
          }
          .flatten(on: req)
          .flatMap { _ -> EventLoopFuture<View> in
            return newImages.map { image in
              return artist.images.attach(image, on: req)
            }
            .flatten(on: req)
            .flatMap { _ -> EventLoopFuture<View> in
              let data = ["artists": Artist.query(on: req).sort(\Artist.name, .ascending).all()]
              return try req.view().render("artistManagement", data)
            }
          }
        }
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
