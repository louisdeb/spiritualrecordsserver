//
//  ReleaseResponse.swift
//  App
//
//  Created by Louis de Beaumont on 21/10/2019.
//

import Vapor

struct ReleaseResponse: Content {
  var release: Release
  var artists: [Artist]
  
  init(release: Release, artists: [Artist]) {
    self.release = release
    self.artists = artists
  }
}
