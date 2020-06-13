//
//  RedirectMiddleware.swift
//  
//
//  Created by Louis de Beaumont on 13/06/2020.
//

import Vapor

struct RedirectMiddleware: Middleware {
  func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
    do {
      let _ = try request.auth.require(User.self)
      return next.respond(to: request)
    } catch {}
    let redirect = request.redirect(to: "/login")
    return request.eventLoop.makeSucceededFuture(redirect)
  }
}
