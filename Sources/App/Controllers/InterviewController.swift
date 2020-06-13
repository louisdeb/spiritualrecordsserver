//
//  InterviewController.swift
//  App
//
//  Created by Louis de Beaumont on 31/10/2019.
//

import Vapor
import Fluent

struct InterviewController: RouteCollection {
 
  func boot(routes: RoutesBuilder) {
    let route = routes.grouped("api", "interview")
    
    route.get(use: get)
    
    let auth = route.grouped([
      User.sessionAuthenticator(),
      RedirectMiddleware(),
    ])
    
    auth.post(use: create)
    auth.post(":interviewID", "delete", use: delete)
  }

  func get(req: Request) -> EventLoopFuture<[InterviewResponse]> {
    let interviewsQuery = Interview.query(on: req.db).sort("date", .descending).all()
    
    return interviewsQuery.flatMap { interviews in
      return interviews.map { interview in
        let artistsQuery = interview.$artists.query(on: req.db).all()
        return artistsQuery.flatMap { artists in
          return artists.map { artist in
            return artist.getPreview(db: req.db)
          }
          .flatten(on: req.eventLoop)
          .map { artistPreviews in
            return InterviewResponse(interview: interview, artists: artistPreviews)
          }
        }
      }
      .flatten(on: req.eventLoop)
    }
  }
  
  func create(req: Request) -> EventLoopFuture<Interview> {
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
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Invalid interview name"))
    }
    
    guard let dateJSON = json["date"] as? String else {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Bad date value"))
    }
    
    guard let date = formatter.date(from: dateJSON) else {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Date value could not be converted to DateTime obejct"))
    }
    
    let shortDescription = json["short-description"] as? String
    let description = json["description"] as? String
    let imageURL = json["imageURL"] as? String
    let videoURL = json["videoURL"] as? String
    
    let interview = Interview(
      name: name,
      date: date,
      shortDescription: shortDescription,
      description: description,
      imageURL: imageURL,
      videoURL: videoURL
    )
    
    let artistsQuery = Artist.query(on: req.db).all()
    
    guard let artistNames = json["artists"] as? [String] else {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("[artists] was not a valid array"))
    }
    
    if json["id"] != nil {
      guard let _id = json["id"] as? String else {
        return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Bad id value"))
      }
      
      guard let id = UUID(uuidString: _id) else {
        return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Id was not a valid UUID"))
      }
      
      return artistsQuery.flatMap { artists in
        let artists = artists.filter { artistNames.contains($0.name) }
        return self.update(req: req, id: id, updatedInterview: interview, artists: artists)
      }
    }
    
    let interviewSaveRequest = interview.save(on: req.db)
    
    return artistsQuery.and(interviewSaveRequest).flatMap { (artists, _) in
      let artists = artists.filter { artistNames.contains($0.name) }
      
      return artists.map { artist in
        return interview.$artists.attach(artist, on: req.db)
      }
      .flatten(on: req.eventLoop)
      .transform(to: interview)
    }
  }

  func update(req: Request, id: UUID, updatedInterview: Interview, artists: [Artist]) -> EventLoopFuture<Interview> {
    Interview.find(id, on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { interview in
        
        interview.name = updatedInterview.name
        interview.date = updatedInterview.date
        interview.shortDescription = updatedInterview.shortDescription
        interview.description = updatedInterview.description
        interview.imageURL = updatedInterview.imageURL
        interview.videoURL = updatedInterview.videoURL
        
        let artistsDetachRequest = interview.$artists.detach(artists, on: req.db)
        let interviewSaveRequest = interview.save(on: req.db)
        
        return artistsDetachRequest.and(interviewSaveRequest).flatMap { (_, _) in
          return artists.map { artist in
            return interview.$artists.attach(artist, on: req.db)
          }
          .flatten(on: req.eventLoop)
          .transform(to: interview)
        }
      }
  }
  
  func delete(req: Request) -> EventLoopFuture<Response> {
    let redirect = req.redirect(to: "/app/interviews")
    
    return Interview.find(req.parameters.get("interview"), on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { interview in
        return interview.delete(on: req.db).transform(to: redirect)
      }
  }
}
