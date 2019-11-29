//
//  NewsController.swift
//  App
//
//  Created by Louis de Beaumont on 12/11/2019.
//

import Vapor
import Authentication

struct ArticleController: RouteCollection {
  func boot(router: Router) throws {
    let route = router.grouped("api", "article")
    
    route.get(use: get)
    
    let sessionMiddleware = User.authSessionsMiddleware()
    let redirectMiddleware = RedirectMiddleware(A: User.self, path: "/login")
    let auth = route.grouped(sessionMiddleware, redirectMiddleware)
    
    auth.post(use: create)
    auth.post(Article.parameter, "delete", use: delete)
  }

  func get(_ req: Request) throws -> Future<[Article]> {
    return Article.query(on: req).sort(\Article.date, .descending).all()
  }
  
  func create(_ req: Request) throws -> Future<Article> {
    let body = req.http.body.description

    guard let data = body.data(using: .utf8) else {
      throw CreateError.runtimeError("Bad request body")
    }

    guard let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, Any> else {
      throw CreateError.runtimeError("Could not parse request body as JSON")
    }
    
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)

    guard let title = json["title"] as? String else {
      throw CreateError.runtimeError("Invalid title")
    }
    
    guard let dateJSON = json["date"] as? String else {
      throw CreateError.runtimeError("Bad date value")
    }

    guard let date = formatter.date(from: dateJSON) else {
      throw CreateError.runtimeError("Date value could not be converted to DateTime obejct")
    }
    
    guard let content = json["content"] as? String else {
      throw CreateError.runtimeError("Invalid content")
    }
    
    guard let author = json["author"] as? String else {
      throw CreateError.runtimeError("Invalid author")
    }
    
    let authorLink = json["authorLink"] as? String
    
    let article = Article(title: title,
                    date: date,
                    content: content,
                    author: author,
                    authorLink: authorLink)
    
    if json["id"] != nil {
      guard let _id = json["id"] as? String else {
        throw CreateError.runtimeError("Bad id value")
      }
      
      guard let id = UUID(uuidString: _id) else {
        throw CreateError.runtimeError("Id was not a valid UUID")
      }
      
      return try self.update(req, id: id, updatedArticle: article)
    }
    
    let user = try req.requireAuthenticated(User.self)
    print("User \(user.username) created Article ID(\(String(describing: article.id))). Title: \(article.title), Date: \(article.date), Content: \(article.content), Author: \(article.author), AuthorLink: \(article.authorLink)")
    
    return article.save(on: req)
  }

  func update(_ req: Request, id: UUID, updatedArticle: Article) throws -> Future<Article> {
    let articleFuture = Article.find(id, on: req)
    
    return articleFuture.flatMap { article_ -> EventLoopFuture<Article> in
      guard let article = article_ else {
        throw CreateError.runtimeError("Could not find article to update")
      }
      
      article.title = updatedArticle.title
      article.date = updatedArticle.date
      article.content = updatedArticle.content
      article.author = updatedArticle.author
      article.authorLink = updatedArticle.authorLink
      
      let user = try req.requireAuthenticated(User.self)
      print("User \(user.username) updated Article ID(\(String(describing: article.id))). Title: \(article.title), Date: \(article.date), Content: \(article.content), Author: \(article.author), AuthorLink: \(article.authorLink)")
      
      return article.save(on: req)
    }
  }
  
  func delete(_ req: Request) throws -> Future<Article> {
    let article = try req.parameters.next(Article.self)
    
    let _ = article.flatMap { (article) -> EventLoopFuture<Article> in
      let user = try req.requireAuthenticated(User.self)
      print("User \(user.username) deleted Article ID(\(String(describing: article.id))). Title: \(article.title), Date: \(article.date), Content: \(article.content), Author: \(article.author), AuthorLink: \(article.authorLink)")
      
      return Future.map(on: req, { () -> Article in
        return article
      })
    }
    
    return article.delete(on: req)
  }
}

