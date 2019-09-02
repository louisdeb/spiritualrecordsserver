//
//  EventController.swift
//  App
//
//  Created by Louis de Beaumont on 02/09/2019.
//

import Vapor
import Authentication

struct EventController: RouteCollection {
  func boot(router: Router) throws {
    let route = router.grouped("api", "event")
    route.post(use: create)
    route.get(use: get)
  }
  
  func create(_ req: Request) throws -> Future<Event> {
    let body = req.http.body.description
    
    let startIndex = body.index(body.startIndex, offsetBy: String("date=").count)
    let endIndex = body.index(body.startIndex, offsetBy: String("date=yyyy-mm-dd").count - 1)
    let dateString = String(body[startIndex...endIndex])
    
    var artistsString = String(body[body.index(endIndex, offsetBy: String("&artists=").count + 1)...])
    artistsString = artistsString.replacingOccurrences(of: "&artists=", with: ",")
    
    let artistNames = artistsString.split(separator: ",").map { s -> String in
      return String(s)
    }
    
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    
    let date = formatter.date(from: dateString)
    
    return Artist.query(on: req).all().flatMap({ (artistFutures) -> Future<Event> in
      let artists = artistFutures.filter { artistNames.contains($0.name) }
      return Event(date: date!, artists: artists).save(on: req)
    })
  }
  
  func get(_ req: Request) throws -> Future<[Event]> {
    return Event.query(on: req).all()
  }
}
