//
//  AppController.swift
//  App
//
//  Created by Louis de Beaumont on 02/09/2019.
//

import Vapor
import Fluent

struct AppController: RouteCollection {

  func boot(routes: RoutesBuilder) throws {
    routes.get("login", use: login)
    
    let app = routes.grouped("app")
    
    let auth = app.grouped([
//      User.sessionAuthenticator(),
      RedirectMiddleware(),
    ])
    
    auth.get(use: index)
    
    let artists = auth.grouped("artists")
    artists.get(use: artistManagement)
    artists.get(":artistID", use: artistView)
    artists.get(":artistID", "edit", use: artistEdit)
    
    let events = auth.grouped("events")
    events.get(use: eventManagement)
    events.get("all", use: eventViewAll)
    events.get(":eventID", "edit", use: eventEdit)
    
    let releases = auth.grouped("releases")
    releases.get(use: releaseManagement)
    releases.get(":releaseID", "edit", use: releaseEdit)
    
    let interviews = auth.grouped("interviews")
    interviews.get(use: interviewManagement)
    interviews.get(":interviewID", "edit", use: interviewEdit)
    
    let news = auth.grouped("news")
    news.get(use: newsManagement)
    news.get(":articleID", "edit", use: newsEdit)
    
    let account = auth.grouped("account")
    account.get(use: accountManagement)
  }
  
  func index(req: Request) -> EventLoopFuture<View> {
    return req.view.render("index")
  }
  
  func login(req: Request) -> EventLoopFuture<View> {
    return req.view.render("login")
  }
  
  func artistManagement(req: Request) -> EventLoopFuture<View> {
    let artistsQuery: EventLoopFuture<[Artist]> = Artist.query(on: req.db).sort("name", .ascending).all()
    
    return artistsQuery.flatMap { artists in
      return artists.map { artist in
        return artist.getPreview(db: req.db)
      }
      .flatten(on: req.eventLoop)
      .flatMap { artistPreviews in
        return req.view.render("artistManagement", [
          "artistPreviews": artistPreviews
        ])
      }
    }
  }
  
  func artistView(req: Request) -> EventLoopFuture<View> {
    Artist.find(req.parameters.get("artist"), on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { artist in
        artist.getProfile(db: req.db)
          .flatMap { artistProfile in
            return req.view.render("artistView", [
              "artistProfile": artistProfile
            ])
          }
      }
  }
  
  func artistEdit(req: Request) -> EventLoopFuture<View> {
    Artist.find(req.parameters.get("artist"), on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { artist in
        artist.getProfile(db: req.db)
          .flatMap { artistProfile in
            return req.view.render("artistEdit", [
              "artistProfile": artistProfile
            ])
          }
      }
  }
  
  func getEventsView(req: Request, viewAll: Bool) -> EventLoopFuture<View> {
    Event.query(on: req.db)
      .sort("date", .ascending)
      .all()
      .flatMap { allEvents in
        let events = viewAll ? allEvents : allEvents.filter { $0.isUpcomingOrThisWeek() }
        let eventResponses: EventLoopFuture<[EventResponse]>
        
        eventResponses = events.map { event in
          let artistsQuery = event.$artists.query(on: req.db).all()
          return artistsQuery.flatMap { artists in
            return artists.map { artist in
              return artist.getPreview(db: req.db)
            }
            .flatten(on: req.eventLoop)
            .map { artistPreviews in
              return EventResponse(event: event, artists: artistPreviews)
            }
          }
        }
        .flatten(on: req.eventLoop)
        
        return eventResponses.flatMap { eventResponses in
          let data = ["eventResponses": eventResponses]
          return viewAll
            ? req.view.render("eventViewAll", data)
            : req.view.render("eventManagement", data)
        }
      }
  }
  
  func eventManagement(req: Request) -> EventLoopFuture<View> {
    return getEventsView(req: req, viewAll: false)
  }
  
  func eventViewAll(req: Request) -> EventLoopFuture<View> {
    return getEventsView(req: req, viewAll: true)
  }
  
  func eventEdit(req: Request) -> EventLoopFuture<View> {
    Event.find(req.parameters.get("event"), on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { event -> EventLoopFuture<View> in
        let artistsQuery = event.$artists.query(on: req.db).all()
        
        return artistsQuery.flatMap { artists -> EventLoopFuture<View> in
          return artists.map { artist -> EventLoopFuture<Artist.Preview> in
            return artist.getPreview(db: req.db)
          }
          .flatten(on: req.eventLoop)
          .flatMap { artistPreviews -> EventLoopFuture<View> in
            let eventResponse = EventResponse(event: event, artists: artistPreviews)
            let data = ["eventResponse": eventResponse]
            return req.view.render("eventEdit", data)
          }
        }
      }
  }
  
  func releaseManagement(req: Request) -> EventLoopFuture<View> {
    Release.query(on: req.db)
      .sort("date", .descending)
      .all()
      .flatMap { releases in
        let releaseResponses: EventLoopFuture<[ReleaseResponse]>
        
        releaseResponses = releases.map { release in
          let imageQuery = release.$images.query(on: req.db).first()
          let artistsQuery = release.$artists.query(on: req.db).all()
          
          return imageQuery.and(artistsQuery).flatMap { (image, artists) in
            let image = image ?? Image(url: "", creditText: "", creditLink: "", index: 0)
            
            return artists.map { artist in
              return artist.getPreview(db: req.db)
            }
            .flatten(on: req.eventLoop)
            .flatMap { artistPreviews in
              return req.eventLoop.future(ReleaseResponse(release: release, artists: artistPreviews, image: image))
            }
          }
        }
        .flatten(on: req.eventLoop)
        
        return releaseResponses.flatMap { releaseResponses in
          return req.view.render("releaseManagement", [
            "releaseResponses": releaseResponses
          ])
        }
      }
  }
  
  func releaseEdit(req: Request) -> EventLoopFuture<View> {
    Release.find(req.parameters.get("release"), on: req.db)
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
            .flatMap { artistPreviews in
              let releaseResponse = ReleaseResponse(release: release, artists: artistPreviews, image: image)
              let data = ["releaseResponse": releaseResponse]
              return req.view.render("releaseEdit", data)
            }
          }
        }
      }
  }
  
  func interviewManagement(req: Request) -> EventLoopFuture<View> {
    let interviewsQuery = Interview.query(on: req.db).sort("date", .descending).all()
    
    return interviewsQuery.flatMap { interviews in
      let interviewResponses: EventLoopFuture<[InterviewResponse]>
      interviewResponses = interviews.map { interview in
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
        
      return interviewResponses.flatMap { interviewResponses in
        return req.view.render("interviewManagement", [
          "interviewResponses": interviewResponses
        ])
      }
    }
  }
  
  func interviewEdit(req: Request) -> EventLoopFuture<View> {
    Interview.find(req.parameters.get("interview"), on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { interview in
        let artistsQuery = interview.$artists.query(on: req.db).all()
        
        return artistsQuery.flatMap { artists in
          return artists.map { artist in
            return artist.getPreview(db: req.db)
          }
          .flatten(on: req.eventLoop)
          .flatMap { artistPreviews in
            let interviewResponse = InterviewResponse(interview: interview, artists: artistPreviews)
            let data = ["interviewResponse": interviewResponse]
            return req.view.render("interviewEdit", data)
          }
        }
      }
  }
  
  func newsManagement(req: Request) -> EventLoopFuture<View> {
    Article.query(on: req.db).sort("date", .descending)
      .all()
      .flatMap { articles in
        return req.view.render("newsManagement", [
          "articles": articles
        ])
      }
  }
  
  func newsEdit(req: Request) -> EventLoopFuture<View> {
    Article.find(req.parameters.get("article"), on: req.db)
      .flatMap { article in
        guard let article = article else {
          return req.eventLoop.future(error: QueryError.runtimeError("Could not find article"))
        }
        return req.view.render("newsEdit", [
          "article": article
        ])
      }
  }
  
  func accountManagement(req: Request) -> EventLoopFuture<View> {
    return req.view.render("accountManagement")
  }
}
