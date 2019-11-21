//
//  InterviewResponse.swift
//  App
//
//  Created by Louis de Beaumont on 31/10/2019.
//

import Vapor

struct InterviewResponse: Content {
  var interview: Interview
  var artistPreviews: [Artist.Preview]
  
  init(interview: Interview, artists: [Artist.Preview]) {
    self.interview = interview
    self.artistPreviews = artists
  }
}
