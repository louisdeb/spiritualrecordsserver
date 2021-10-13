//
//  ArtistController.swift
//  App
//
//  Created by Louis de Beaumont on 02/09/2019.
//

import Vapor
import Fluent
import S3

struct ArtistController: RouteCollection {
  /* AWS
  let awsController: AwsController
  
  init(awsController: AwsController) {
    self.awsController = awsController
  }
  */
  
  func boot(routes: RoutesBuilder) throws {
    let route = routes.grouped("api", "artist")
    
    route.get(use: get)
    route.get(":artistID", use: getResponse)
    
    let auth = route.grouped([
//      User.sessionAuthenticator(),
      RedirectMiddleware(),
    ])
    
    auth.post(use: create)
    auth.post(":artistID", "delete", use: delete)
  }
  
  func get(req: Request) -> EventLoopFuture<[Artist.Preview]> {
    let artistsQuery = Artist.query(on: req.db).sort("name", .ascending).all()
    
    return artistsQuery.flatMap { artists in
      return artists.map { artist in
        return artist.getPreview(db: req.db)
      }
      .flatten(on: req.eventLoop)
    }
  }
  
  func getResponse(req: Request) -> EventLoopFuture<ArtistResponse> {
    Artist.find(req.parameters.get("artist"), on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { artist in
        let imagesQuery = artist.$images.query(on: req.db).sort("index", .ascending).all()
        let eventsQuery = artist.$events.query(on: req.db).sort("date", .ascending).all()
        let releasesQuery = artist.$releases.query(on: req.db).all()
        
        return imagesQuery.and(eventsQuery).and(releasesQuery).map { result in
          let ((images, _events), releases) = result
          let events = _events.filter { $0.isUpcoming() }
          return ArtistResponse(artist: artist, images: images, events: events, releases: releases)
        }
      }
  }
  
  func create(req: Request) -> EventLoopFuture<View> {
    let body = req.body.description
    
    guard let data = body.data(using: .utf8) else {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Bad request body"))
    }
    
    let json: Dictionary<String, Any>
    do {
      guard let _json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, Any> else {
        return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Could not parse request body as JSON"))
      }
      json = _json
    } catch {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Could not parse request body as JSON"))
    }
    
    guard let name = json["name"] as? String else {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Invalid artist name"))
    }
    
    let shortDescription = json["shortDescription"] as? String
    let description = json["description"] as? String
    
    let spotify = json["spotify"] as? String
    let appleMusic = json["appleMusic"] as? String
    let googlePlay = json["googlePlay"] as? String
    let instagram = json["instagram"] as? String
    let facebook = json["facebook"] as? String
    let website = json["website"] as? String
    
    let artist = Artist(
      name: name,
      shortDescription: shortDescription,
      description: description,
      spotify: spotify,
      appleMusic: appleMusic,
      googlePlay: googlePlay,
      instagram: instagram,
      facebook: facebook,
      website: website
    )
    
    /*
    guard let uploadedImages = json["images"] as? [Dictionary<String, Any>] else {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Bad value for images"))
    }
    
    guard !uploadedImages.isEmpty else {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("No images were provided"))
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
          return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Bad image ID value"))
        }
        
        guard let uuid = UUID(uuidString: _id) else {
          return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Image ID was not a valid UUID"))
        }
        
        updatedImages.append(ImageUpdateInformation(id: uuid, creditText: creditText, creditLink: creditLink, index: index))
        continue
      }
      
      guard var imageString = imageJson["image"] as? String else {
        return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Uploaded image had bad string"))
      }
      
      imageString.replaceOccurances(pattern: "data:image\\/.*;base64,", with: "")
      
      guard let imageData = Data(base64Encoded: imageString) else {
        return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Image string did not convert to data"))
      }
      
      let presignedUrl = try awsController.preparePresignedUrlForImage(req: req)
      guard let url = URL(string: presignedUrl.url) else {
        return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Couldn't create valid URL from S3 URL string"))
      }
      
      var headers = HTTPHeaders()
      headers.add(name: "x-amz-acl", value: "public-read")
      headers.add(name: "Content-Type", value: "text/plain")
      
      let uploadFuture = try req.client.put(url, headers: headers) { put in
        put.body = imageData.convertToHTTPBody()
      }
      
      imageUploadFutures.append(
        ImageUploadFuture(
          uploadFuture: uploadFuture,
          getUrl: presignedUrl.get,
          creditText: creditText,
          creditLink: creditLink,
          index: index
        )
      )
    }
    
    var images: [Image] = []
    
    let allImagesUploadFuture = imageUploadFutures.map { imageUploadFuture in
      return imageUploadFuture.uploadFuture.flatMap { r in
        if (r.status == .ok) {
          let image = Image(
            url: imageUploadFuture.getUrl,
            creditText: imageUploadFuture.creditText,
            creditLink: imageUploadFuture.creditLink,
            index: imageUploadFuture.index
          )
          
          images.append(image)
          return image.save(on: req.db).transform(to: ())
        }
      }
    }.flatten(on: req.eventLoop)
     */
    
//    return allImagesUploadFuture.flatMap { r in
      if json["id"] != nil {
        guard let idString = json["id"] as? String else {
          return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Bad image ID value"))
        }
        
        guard let id = UUID(uuidString: idString) else {
          return req.eventLoop.makeFailedFuture(CreateError.runtimeError("ID was not a valid UUID"))
        }
        
        return self.update(req: req, id: id, updatedArtist: artist) // newImages: images, updatedImages: updatedImages)
      }
      
      return artist.save(on: req.db).transform(to: artist).flatMap { artist in
//        return images.map { image in
//          return artist.$images.attach(image, on: req.db)
//        }
//        .flatten(on: req.eventLoop)
//        .transform(to: artist)
//        .flatMap { _ in
          return Artist.query(on: req.db).sort("name", .ascending)
            .all()
            .flatMap { artists in
              return req.view.render("artistManagement", [
                "artists": artists
              ])
            }
        }
//      }
//    }
  }
  
  func update(req: Request, id: UUID, updatedArtist: Artist) -> EventLoopFuture<View> { // , newImages: [Image], updatedImages: [ImageUpdateInformation]) -> EventLoopFuture<View> {
    Artist.find(id, on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { artist in
        artist.name = updatedArtist.name
        artist.shortDescription = updatedArtist.shortDescription
        artist.description = updatedArtist.description
        artist.website = updatedArtist.website
        artist.spotify = updatedArtist.spotify
        artist.appleMusic = updatedArtist.appleMusic
        artist.googlePlay = updatedArtist.googlePlay
        artist.instagram = updatedArtist.instagram
        artist.facebook = updatedArtist.facebook
        
        return artist.save(on: req.db).flatMap { _ in
          /*
          let imagesQuery = artist.$images.query(on: req.db).all()
          
          return imagesQuery.flatMap { images in
            return images.map { image in
              let matches = updatedImages.filter { $0.id == image.id! }
              
              if (matches.isEmpty) {
                let detachRequest = artist.$images.detach(image, on: req.db)
                
                return detachRequest.flatMap { _ in
                  let artistsCountQuery = image.$artists.query(on: req.db).count()
                  return artistsCountQuery.flatMap { numberOfArtists in
                    if numberOfArtists == 0 {
                      return image.delete(on: req.db)
                    }
                  }
                }
              }
              
              let updatedImage = matches.first!
              image.creditText = updatedImage.creditText ?? ""
              image.creditLink = updatedImage.creditLink ?? ""
              image.index = updatedImage.index
              
              return image.save(on: req.db).transform(to: ())
            }
            .flatten(on: req.eventLoop)
            .flatMap { _ in
//              return newImages.map { image in
//                return artist.$images.attach(image, on: req.db)
//              }
//              .flatten(on: req.eventLoop)
//              .flatMap { _ in */
                return Artist.query(on: req.db).sort("name", .ascending)
                  .all()
                  .flatMap { artists in
                    return req.view.render("artistManagement", [
                      "artists": artists
                    ])
                  }
//              }
//            }
//          }
        }
      }
  }
  
  func delete(req: Request) -> EventLoopFuture<Response> {
    let redirect = req.redirect(to: "/app/artists")
    
    return Artist.find(req.parameters.get("artist"), on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { artist -> EventLoopFuture<Response> in
        let releasesQuery = artist.$releases.query(on: req.db).all()
        let artistDeleteRequest = artist.delete(on: req.db)
        
        return releasesQuery.and(artistDeleteRequest).flatMap { (releases, _) in
          return releases.map { release in
            let artistsReleasesQuery = release.$artists.query(on: req.db).all()

            return artistsReleasesQuery.flatMap { artists in
              return artists.isEmpty
                ? release.delete(on: req.db)
                : req.eventLoop.future()
            }
          }
          .flatten(on: req.eventLoop)
          .transform(to: redirect)
        }
      }
  }
}
