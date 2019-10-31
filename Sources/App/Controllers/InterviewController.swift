//
//  InterviewController.swift
//  App
//
//  Created by Louis de Beaumont on 31/10/2019.
//

import Vapor
import Authentication

struct InterviewController: RouteCollection {
  func boot(router: Router) throws {
    let route = router.grouped("api", "interview")
    
    route.get(use: get)
    
    let sessionMiddleware = User.authSessionsMiddleware()
    let redirectMiddleware = RedirectMiddleware(A: User.self, path: "/login")
    let auth = route.grouped(sessionMiddleware, redirectMiddleware)
    
    auth.post(use: create)
    auth.post(Interview.parameter, "delete", use: delete)
  }

  func get(_ req: Request) throws -> Future<[InterviewResponse]> {
    let interviews = Interview.query(on: req).sort(\Interview.date, .descending).all()
    
    return interviews.flatMap { interviews -> EventLoopFuture<[InterviewResponse]> in
      return try interviews.map { interview -> Future<InterviewResponse> in
        return try interview.artists.query(on: req).all().flatMap { artists -> EventLoopFuture<InterviewResponse> in
          return Future.map(on: req, { () -> InterviewResponse in
            return InterviewResponse(interview: interview, artists: artists)
          })
        }
      }
      .flatten(on: req)
    }
  }
  
  func create(_ req: Request) throws -> Future<Interview> {
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
    let shortDescription = json["short-description"] as? String
    let description = json["description"] as? String
    let videoURL = json["videoURL"] as? String
    
    let interview = Interview(name: name,
                              date: date,
                              shortDescription: shortDescription,
                              description: description,
                              videoURL: videoURL)
    
    let artists = Artist.query(on: req).all()
    let artistNames = json["artists"] as! [String]
    
    if json["id"] != nil {
      let id = UUID(uuidString: json["id"] as! String)!
      return artists.flatMap { artists -> EventLoopFuture<Interview> in
        let artists = artists.filter { artistNames.contains($0.name) }
        return try self.update(req, id: id, updatedInterview: interview, artists: artists)
      }
    }
    
    return flatMap(artists, interview.save(on: req), { (allArtists, interview) -> EventLoopFuture<Interview> in
      let artists = allArtists.filter { artistNames.contains($0.name) }
      
      return artists.map { artist in
        return interview.artists.attach(artist, on: req)
      }
      .flatten(on: req)
      .transform(to: interview)
    })
  }

  func update(_ req: Request, id: UUID, updatedInterview: Interview, artists: [Artist]) throws -> Future<Interview> {
    let interviewFuture = Interview.find(id, on: req)
    
    return interviewFuture.flatMap { interview_ -> EventLoopFuture<Interview> in
      guard let interview = interview_ else {
        throw CreateError.runtimeError("Could not find interview to update")
      }
      
      interview.name = updatedInterview.name
      interview.date = updatedInterview.date
      interview.shortDescription = updatedInterview.shortDescription
      interview.description = updatedInterview.description
      
      return flatMap(interview.artists.detachAll(on: req), interview.save(on: req), { (_, interview) -> EventLoopFuture<Interview> in
        return artists.map { artist in
          return interview.artists.attach(artist, on: req)
        }
        .flatten(on: req)
        .transform(to: interview)
      })
    }
  }
  
  func delete(_ req: Request) throws -> Future<Interview> {
    let interview = try req.parameters.next(Interview.self)
    return interview.delete(on: req)
  }
}


