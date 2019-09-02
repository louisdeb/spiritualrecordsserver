//
//  EventDateTime.swift
//  App
//
//  Created by Louis de Beaumont on 02/09/2019.
//

import FluentSQLite
import Vapor

final class EventDateTime: Codable {
  var id: UUID?
  
  var year: Int
  var month: Int
  var date: Int
  var hour: Int
  var min: Int
}

extension EventDateTime: SQLiteUUIDModel {}
extension EventDateTime: Content {}
extension EventDateTime: Parameter {}
