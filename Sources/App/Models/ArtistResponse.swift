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
  var releases: [Release]
  
  init(artist: Artist, events: [Event], releases: [Release]) {
    self.artist = artist
    self.events = events
    self.releases = releases
  }
}
