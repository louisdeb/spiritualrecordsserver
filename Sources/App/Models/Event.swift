//
//  Event.swift
//  App
//
//  Created by Louis de Beaumont on 01/09/2019.
//

import FluentSQLite
import Vapor

final class Event: Codable {
  var id: UUID?
  
  var name: String
  var date: Date
  var unsignedArtists: [String]
  var price: String
  
  init(name: String?, date: Date, unsignedArtists: [String], price: String) {
    self.name = name == "" ? Event.generateName(date: date) : name ?? Event.generateName(date: date)
    self.date = date
    self.unsignedArtists = unsignedArtists
    self.price = price
  }
}

extension Event {
  var artists : Siblings<Event, Artist, ArtistEventPivot> {
    return siblings()
  }
}

extension Event {
  static func isUpcoming(event: Event) -> Bool {
    let now = Date.init(timeIntervalSinceNow: 0)
    let calendar = Calendar.current
    let year = calendar.component(.year, from: now)
    let month = calendar.component(.month, from: now)
    let day = calendar.component(.day, from: now)
    
    var dateComponents = DateComponents()
    dateComponents.year = year
    dateComponents.month = month
    dateComponents.day = day
    dateComponents.minute = 0
    dateComponents.second = 0
    
    let today = calendar.date(from: dateComponents)!
    
    return event.date >= today
  }
  
  static func generateName(date: Date) -> String {
    let calendar = Calendar.current
    let weekday = calendar.component(.weekday, from: date)
    let day = calendar.component(.day, from: date)
    let month = calendar.component(.month, from: date)
    
    var generatedName = calendar.weekdaySymbols[weekday-1]
    generatedName += " " + String(day)
    generatedName += " " + calendar.shortMonthSymbols[month]
    generatedName += " Live"
    
    return generatedName
  }
}

extension Event: Migration {
  static func prepare(on connection: SQLiteConnection) -> Future<Void> {
    return Database.create(self, on: connection) { builder in
      try addProperties(to: builder)
      builder.unique(on: \.id)
    }
  }
}

extension Event: SQLiteUUIDModel {}
extension Event: Content {}
extension Event: Parameter {}

// Could add a default event for open mics

struct EventResponse: Content {
  var event: Event
  var artists: [Artist]
  
  init(event: Event, artists: [Artist]) {
    self.event = event
    self.artists = artists
  }
}
