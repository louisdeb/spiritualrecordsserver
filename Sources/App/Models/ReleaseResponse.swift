//
//  ReleaseResponse.swift
//  App
//
//  Created by Louis de Beaumont on 21/10/2019.
//

import Vapor

struct ReleaseResponse: Content {
  var release: Release
  var artistPreviews: [Artist.Preview]
  
  init(release: Release, artists: [Artist.Preview]) {
    self.release = release
    self.artistPreviews = artists
  }
}
