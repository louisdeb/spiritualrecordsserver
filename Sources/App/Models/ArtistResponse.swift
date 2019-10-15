//
//  ArtistResponse.swift
//  App
//
//  Created by Louis de Beaumont on 07/10/2019.
//

import Vapor

struct ArtistResponse: Content {
  var artist: Artist
  var eventResponses: [EventResponse]
  
  init(artist: Artist, eventResponses: [EventResponse]) {
    self.artist = artist
    self.eventResponses = eventResponses
  }
}
