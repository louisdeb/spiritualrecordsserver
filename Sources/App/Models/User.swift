//
//  User.swift
//  App
//
//  Created by Louis de Beaumont on 04/09/2019.
//

import Vapor
import Fluent

final class User: Model {
  static let schema = "User"
  
  @ID(key: .id)
  var id: UUID?
  
  @Field(key: "username")
  var username: String
  
  @Field(key: "password")
  var password: String
  
  init() {}
  
  init(username: String, password: String) {
    self.username = username
    self.password = password
  }
}

extension User {
  struct Create: Migration {
    let name = User.schema
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
      database.schema(name)
        .field("id", .uuid, .identifier(auto: true))
        .field("username", .uuid, .required)
        .field("password", .uuid, .required)
        .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
      database.schema(name).delete()
    }
  }
}

extension User: Content {}

extension User: Authenticatable {}

struct UserAuthenticator: BasicAuthenticator {
  typealias User = App.User

  func authenticate(basic: BasicAuthorization, for request: Request) -> EventLoopFuture<Void> {
    return User.query(on: request.db)
      .filter(\.$username == basic.username)
      .first()
      .map { user -> EventLoopFuture<Void> in
        do {
          if let user = user, try Bcrypt.verify(basic.password, created: user.password) {
            request.auth.login(user)
          }
        }
        catch {}
        return request.eventLoop.makeSucceededFuture(())
      }
      .transform(to: ())
  }
}

extension User: SessionAuthenticatable {
  typealias SessionID = UUID
  var sessionID: SessionID { self.id! }
}

struct UserSessionAuthenticator: SessionAuthenticator {
  typealias User = App.User
  
  func authenticate(sessionID: User.SessionID, for request: Request) -> EventLoopFuture<Void> {
    User.find(sessionID, on: request.db)
      .map { user in
        if let user = user {
          request.auth.login(user)
        }
      }
  }
}
