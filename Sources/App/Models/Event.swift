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
  var artists: [Artist]
  var unsignedArtists: [String]
  var price: String
  
  init(name: String?, date: Date, artists: [Artist], unsignedArtists: [String], price: String) {
    self.name = name ?? date.description // Temporary - elaborate with 'Tuesday Live 18th Oct', e.g.
    self.date = date
    self.artists = artists
    self.unsignedArtists = unsignedArtists
    self.price = price
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
