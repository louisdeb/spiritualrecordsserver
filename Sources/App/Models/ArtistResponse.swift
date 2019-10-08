//
//  ArtistResponse.swift
//  App
//
//  Created by Louis de Beaumont on 07/10/2019.
//

import Vapor

struct ArtistResponse: Content {
  var artist: Artist
  var events: [Event]
  
  init(artist: Artist, events: [Event]) {
    self.artist = artist
    self.events = events
  }
}
