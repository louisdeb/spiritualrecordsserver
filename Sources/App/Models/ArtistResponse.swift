//
//  ArtistResponse.swift
//  App
//
//  Created by Louis de Beaumont on 07/10/2019.
//

import Vapor

struct ArtistResponse: Content {
  var artist: Artist
  var images: [Image]
  var events: [Event]
  var releases: [Release]
  
  init(artist: Artist, images: [Image], events: [Event], releases: [Release]) {
    self.artist = artist
    self.images = images
    self.events = events
    self.releases = releases
  }
  
  final class Profile: Codable {
    var artist: Artist
    var images: [Image]
    
    init(artist: Artist, images: [Image]) {
      self.artist = artist
      self.images = images
    }
  }
}
