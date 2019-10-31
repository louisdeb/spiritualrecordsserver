//
//  InterviewResponse.swift
//  App
//
//  Created by Louis de Beaumont on 31/10/2019.
//

import Vapor

struct InterviewResponse: Content {
  var interview: Interview
  var artists: [Artist]
  
  init(interview: Interview, artists: [Artist]) {
    self.interview = interview
    self.artists = artists
  }
}
