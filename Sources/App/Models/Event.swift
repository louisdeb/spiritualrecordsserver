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
  var description: String
  var unsignedArtists: [String]
  var price: String
  var noEvent: Bool
  
  init(name: String?, date: Date, description: String?, unsignedArtists: [String], price: String, noEvent: Bool = false) {
//    The following line creates a name for all events.
//    self.name = (name == nil || name == "") ? Event.generateName(date: date) : name!
    self.name = name ?? ""
    self.date = date
    self.description = description ?? ""
    self.unsignedArtists = unsignedArtists
    self.price = price
    
    self.noEvent = noEvent
    if (noEvent) {
      self.id = UUID.init()
    }
  }
}

extension Event {
  var artists : Siblings<Event, Artist, ArtistEventPivot> {
    return siblings()
  }
}

extension Event {
  func isUpcoming() -> Bool {
    let now = Date()
    let calendar = Calendar(identifier: .gregorian)
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
    
    return self.date >= today
  }
  
  static func generateName(date: Date) -> String {
    let calendar = Calendar(identifier: .gregorian)
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
