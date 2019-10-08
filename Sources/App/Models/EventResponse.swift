//
//  EventResponse.swift
//  App
//
//  Created by Louis de Beaumont on 07/10/2019.
//

import Vapor

struct EventResponse: Content {
  var event: Event
  var artists: [Artist]
  
  init(event: Event, artists: [Artist]) {
    self.event = event
    self.artists = artists
  }
}
