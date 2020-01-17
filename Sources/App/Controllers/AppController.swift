//
//  AppController.swift
//  App
//
//  Created by Louis de Beaumont on 02/09/2019.
//

import Vapor
import Authentication

struct AppController: RouteCollection {
  func boot(router: Router) throws {
    router.get("login", use: login)
    
    let app = router.grouped("app")
    
    let sessionMiddleware = User.authSessionsMiddleware()
    let redirectMiddleware = RedirectMiddleware(A: User.self, path: "/login")
    let auth = app.grouped(sessionMiddleware, redirectMiddleware)
    
    auth.get(use: index)
    
    let artists = auth.grouped("artists")
    artists.get(use: artistManagement)
    artists.get(Artist.parameter, use: artistView)
    artists.get(Artist.parameter, "edit", use: artistEdit)
    
    let events = auth.grouped("events")
    events.get(use: eventManagement)
    events.get("all", use: eventViewAll)
    events.get(Event.parameter, "edit", use: eventEdit)
    
    let releases = auth.grouped("releases")
    releases.get(use: releaseManagement)
    releases.get(Release.parameter, "edit", use: releaseEdit)
    
    let interviews = auth.grouped("interviews")
    interviews.get(use: interviewManagement)
    interviews.get(Interview.parameter, "edit", use: interviewEdit)
    
    let news = auth.grouped("news")
    news.get(use: newsManagement)
    news.get(Article.parameter, "edit", use: newsEdit)
    
    let account = auth.grouped("account")
    account.get(use: accountManagement)
  }
  
  func index(_ req: Request) throws -> Future<View> {
    return try req.view().render("index")
  }
  
  func login(_ req: Request) throws -> Future<View> {
    return try req.view().render("login")
  }
  
  func artistManagement(_ req: Request) throws -> Future<View> {
    let artists = Artist.query(on: req).sort(\Artist.name, .ascending).all()
    
    return artists.flatMap { artists -> EventLoopFuture<View> in
      let artistPreviews = try artists.map { artist -> Future<Artist.Preview> in
        return try artist.getPreview(req)
      }
      .flatten(on: req)
      
      let data = ["artistPreviews": artistPreviews]
      return try req.view().render("artistManagement", data)
    }
  }
  
  func artistView(_ req: Request) throws -> Future<View> {
    let artist = try req.parameters.next(Artist.self)
    return artist.flatMap { artist -> EventLoopFuture<View> in
      let artistProfile = try artist.getProfile(req)
      let data = ["artistProfile": artistProfile]
      return try req.view().render("artistView", data)
    }
  }
  
  func artistEdit(_ req: Request) throws -> Future<View> {
    let artist = try req.parameters.next(Artist.self)
    return artist.flatMap { artist -> EventLoopFuture<View> in
      let artistProfile = try artist.getProfile(req)
      let data = ["artistProfile": artistProfile]
      return try req.view().render("artistEdit", data)
    }
  }
  
  func getEventsView(_ req: Request, viewAll: Bool) throws -> Future<View> {
    let events = Event.query(on: req).sort(\Event.date, .ascending).all()
    
    return events.flatMap { _events -> EventLoopFuture<View> in
      let events = viewAll ? _events : _events.filter { $0.isUpcomingOrThisWeek() }
      
      let eventResponses = try events.map { event -> Future<EventResponse> in
        return try event.artists.query(on: req).all().flatMap { artists -> EventLoopFuture<EventResponse> in
          return try artists.map { artist -> EventLoopFuture<Artist.Preview> in
            return try artist.getPreview(req)
          }
          .flatten(on: req)
          .flatMap { artistPreviews -> EventLoopFuture<EventResponse> in
            return Future.map(on: req, { () -> EventResponse in
              return EventResponse(event: event, artists: artistPreviews)
            })
          }
        }
      }
      .flatten(on: req)
      
      return eventResponses.flatMap { eventResponses -> EventLoopFuture<View> in
        let data = ["eventResponses": eventResponses]
        return viewAll ? try req.view().render("eventViewAll", data) : try req.view().render("eventManagement", data)
      }
    }
  }
  
  func eventManagement(_ req: Request) throws -> Future<View> {
    return try getEventsView(req, viewAll: false)
  }
  
  func eventViewAll(_ req: Request) throws -> Future<View> {
    return try getEventsView(req, viewAll: true)
  }
  
  func eventEdit(_ req: Request) throws -> Future<View> {
    let event = try req.parameters.next(Event.self)
    return event.flatMap { event -> EventLoopFuture<View> in
      return try event.artists.query(on: req).all().flatMap { artists -> EventLoopFuture<View> in
        return try artists.map { artist -> EventLoopFuture<Artist.Preview> in
          return try artist.getPreview(req)
        }
        .flatten(on: req)
        .flatMap { artistPreviews -> EventLoopFuture<View> in
          let eventResponse = EventResponse(event: event, artists: artistPreviews)
          let data = ["eventResponse": eventResponse]
          return try req.view().render("eventEdit", data)
        }
      }
    }
  }
  
  func releaseManagement(_ req: Request) throws -> Future<View> {
    let releases = Release.query(on: req).sort(\Release.date, .descending).all()
    
    return releases.flatMap { releases -> EventLoopFuture<View> in
      let releaseResponses = try releases.map { release -> EventLoopFuture<ReleaseResponse> in
        return try release.images.query(on: req).first().flatMap { image_ -> EventLoopFuture<ReleaseResponse> in
          let image = image_ ?? Image(url: "", creditText: "", creditLink: "", index: 0)
          
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
      
      return releaseResponses.flatMap { releaseResponses -> EventLoopFuture<View> in
        let data = ["releaseResponses": releaseResponses]
        return try req.view().render("releaseManagement", data)
      }
    }
  }
  
  func releaseEdit(_ req: Request) throws -> Future<View> {
    let release = try req.parameters.next(Release.self)
    
    return release.flatMap { release -> EventLoopFuture<View> in
      return try release.images.query(on: req).first().flatMap { image_ -> EventLoopFuture<View> in
        let image = image_ ?? Image(url: "", creditText: "", creditLink: "", index: 0)
        
        return try release.artists.query(on: req).all().flatMap { artists -> EventLoopFuture<View> in
          return try artists.map { artist -> EventLoopFuture<Artist.Preview> in
            return try artist.getPreview(req)
          }
          .flatten(on: req)
          .flatMap { artistPreviews -> EventLoopFuture<View> in
            let releaseResponse = ReleaseResponse(release: release, artists: artistPreviews, image: image)
            let data = ["releaseResponse": releaseResponse]
            return try req.view().render("releaseEdit", data)
          }
        }
      }
    }
  }
  
  func interviewManagement(_ req: Request) throws -> Future<View> {
    let interviews = Interview.query(on: req).sort(\Interview.date, .descending).all()
    
    return interviews.flatMap { interviews -> EventLoopFuture<View> in
      let interviewResponses = try interviews.map { interview -> EventLoopFuture<InterviewResponse> in
        return try interview.artists.query(on: req).all().flatMap { artists -> EventLoopFuture<InterviewResponse> in
          return try artists.map { artist -> EventLoopFuture<Artist.Preview> in
            return try artist.getPreview(req)
          }
          .flatten(on: req)
          .flatMap { artistPreviews -> EventLoopFuture<InterviewResponse> in
            return Future.map(on: req, { () -> InterviewResponse in
              return InterviewResponse(interview: interview, artists: artistPreviews)
            })
          }
        }
      }
      .flatten(on: req)
      
      return interviewResponses.flatMap { interviewResponses -> EventLoopFuture<View> in
        let data = ["interviewResponses": interviewResponses]
        return try req.view().render("interviewManagement", data)
      }
    }
  }
  
  func interviewEdit(_ req: Request) throws -> Future<View> {
    let interview = try req.parameters.next(Interview.self)
    
    return interview.flatMap { interview -> EventLoopFuture<View> in
      return try interview.artists.query(on: req).all().flatMap { artists -> EventLoopFuture<View> in
        return try artists.map { artist -> EventLoopFuture<Artist.Preview> in
          return try artist.getPreview(req)
        }
        .flatten(on: req)
        .flatMap { artistPreviews -> EventLoopFuture<View> in
          let interviewResponse = InterviewResponse(interview: interview, artists: artistPreviews)
          let data = ["interviewResponse": interviewResponse]
          return try req.view().render("interviewEdit", data)
        }
      }
    }
  }
  
  func newsManagement(_ req: Request) throws -> Future<View> {
    let news = Article.query(on: req).sort(\Article.date, .descending).all()
    let data = ["news": news]
    return try req.view().render("newsManagement", data)
  }
  
  func newsEdit(_ req: Request) throws -> Future<View> {
    let article = try req.parameters.next(Article.self)
    let data = ["article": article]
    return try req.view().render("newsEdit", data)
  }
  
  func accountManagement(_ req: Request) throws -> Future<View> {
    return try req.view().render("accountManagement")
  }
}
