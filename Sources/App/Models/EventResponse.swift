//
//  EventResponse.swift
//  App
//
//  Created by Louis de Beaumont on 07/10/2019.
//

import Vapor

struct EventResponse: Content {
  var event: Event
  var artistPreviews: [Artist.Preview]
  
  init(event: Event, artists: [Artist.Preview]) {
    self.event = event
    self.artistPreviews = artists
  }
}
