//
//  Event.swift
//  App
//
//  Created by Louis de Beaumont on 01/09/2019.
//

import Fluent
import Vapor

final class Event: Model {
  static let schema = "events"
  
  @ID(key: .id)
  var id: UUID?
  
  @Field(key: "name")
  var name: String
  
  @Field(key: "date")
  var date: Date
  
  @Field(key: "description")
  var description: String
  
  @Field(key: "unsignedArtists")
  var unsignedArtists: [UnsignedArtist]
  
  @Field(key: "price")
  var price: String
  
  @Field(key: "ticketsURL")
  var ticketsURL: String
  
  @Field(key: "noEvent")
  var noEvent: Bool
  
  @Siblings(through: ArtistEvent.self, from: \.$event, to: \.$artist)
  var artists: [Artist]
  
  init() {}
  
  init(name: String?, date: Date, description: String?,
       unsignedArtists: [UnsignedArtist], price: String?,
       ticketsURL: String?, noEvent: Bool = false) {
    
    // The following line creates a name for all events.
    // self.name = (name == nil || name == "") ? Event.generateName(date: date) : name!
    
    self.name = name ?? ""
    self.date = date
    self.description = description ?? ""
    
    var unsignedArtistsMutable = unsignedArtists
    if (unsignedArtistsMutable.isEmpty) {
      unsignedArtistsMutable.append(UnsignedArtist(name: "", link: ""))
    }
    
    self.unsignedArtists = unsignedArtistsMutable
    self.price = price ?? ""
    self.ticketsURL = ticketsURL ?? ""
    
    self.noEvent = noEvent
    if (noEvent) {
      self.id = UUID.init()
    }
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
  
  func isUpcomingOrThisWeek() -> Bool {
    let monday = Date().previous(.monday)
    
    let calendar = Calendar(identifier: .gregorian)
    let year = calendar.component(.year, from: monday)
    let month = calendar.component(.month, from: monday)
    let day = calendar.component(.day, from: monday)
    
    var dateComponents = DateComponents()
    dateComponents.year = year
    dateComponents.month = month
    dateComponents.day = day
    dateComponents.minute = 0
    dateComponents.second = 0
    
    let mondayZero = calendar.date(from: dateComponents)!
    
    return self.date >= mondayZero
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

extension Event {
  struct Create: Migration {
    let name = Event.schema
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
      database.schema(name)
        .field("id", .uuid, .identifier(auto: true))
        .field("name", .uuid, .required)
        .field("date", .uuid, .required)
        .field("description", .uuid, .required)
        .field("unsignedArtists", .uuid, .required)
        .field("price", .uuid, .required)
        .field("ticketsURL", .uuid, .required)
        .field("noEvent", .uuid, .required)
        .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
      database.schema(name).delete()
    }
  }
}

extension Event: Content {}
