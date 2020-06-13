//
//  Article.swift
//  App
//
//  Created by Louis de Beaumont on 12/11/2019.
//

import Fluent
import Vapor

final class Article: Model {
  static let schema = "Article"
  
  @ID(key: .id)
  var id: UUID?
  
  @Field(key: "title")
  var title: String
  
  @Field(key: "date")
  var date: Date
  
  @Field(key: "content")
  var content: String
  
  @Field(key: "author")
  var author: String
  
  @Field(key: "authorLink")
  var authorLink: String
  
  init() {}
  
  init(title: String, date: Date, content: String, author: String, authorLink: String?) {
    self.title = title
    self.date = date
    self.content = content
    self.author = author
    self.authorLink = authorLink ?? ""
  }
}

extension Article {
  struct Create: Migration {
    let name = Article.schema
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
      database.schema(name)
        .field("id", .uuid, .identifier(auto: true))
        .field("title", .uuid, .required)
        .field("date", .uuid, .required)
        .field("content", .uuid, .required)
        .field("author", .uuid, .required)
        .field("authorLink", .uuid, .required)
        .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
      database.schema(name).delete()
    }
  }
}

extension Article: Content {}
