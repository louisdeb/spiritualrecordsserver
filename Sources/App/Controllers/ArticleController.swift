//
//  NewsController.swift
//  App
//
//  Created by Louis de Beaumont on 12/11/2019.
//

import Vapor
import Fluent

struct ArticleController: RouteCollection {
  
  func boot(routes: RoutesBuilder) {
    let route = routes.grouped("api", "article")
    
    route.get(use: get)
    
    let auth = route.grouped([
//      User.sessionAuthenticator(),
      RedirectMiddleware(),
    ])
    
    auth.post(use: create)
    auth.post(":articleID", "delete", use: delete)
  }

  func get(req: Request) -> EventLoopFuture<[Article]> {
    return Article.query(on: req.db).sort("date", .descending).all()
  }
  
  func create(req: Request) -> EventLoopFuture<Article> {
    let body = req.body.description

    guard let data = body.data(using: .utf8) else {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Bad request body"))
    }

    let json: Dictionary<String, Any>
    do {
      guard let _json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, Any> else {
        throw CreateError.runtimeError("Could not parse request body as JSON")
      }
      json = _json
    } catch {
      return req.eventLoop.makeFailedFuture(error)
    }
    
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)

    guard let title = json["title"] as? String else {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Invalid title"))
    }
    
    guard let dateJSON = json["date"] as? String else {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Bad date value"))
    }

    guard let date = formatter.date(from: dateJSON) else {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Date value could not be converted to DateTime obejct"))
    }
    
    guard let content = json["content"] as? String else {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Invalid content"))
    }
    
    guard let author = json["author"] as? String else {
      return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Invalid author"))
    }
    
    let authorLink = json["authorLink"] as? String
    
    let article = Article(title: title,
                    date: date,
                    content: content,
                    author: author,
                    authorLink: authorLink)
    
    if json["id"] != nil {
      guard let _id = json["id"] as? String else {
        return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Bad id value"))
      }
      
      guard let id = UUID(uuidString: _id) else {
        return req.eventLoop.makeFailedFuture(CreateError.runtimeError("Id was not a valid UUID"))
      }
      
      return self.update(req: req, id: id, updatedArticle: article)
    }
    
    return article.save(on: req.db).transform(to: article)
  }

  func update(req: Request, id: UUID, updatedArticle: Article) -> EventLoopFuture<Article> {
    Article.find(id, on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { article -> EventLoopFuture<Article> in
        article.title = updatedArticle.title
        article.date = updatedArticle.date
        article.content = updatedArticle.content
        article.author = updatedArticle.author
        article.authorLink = updatedArticle.authorLink
        
        return article.save(on: req.db).transform(to: article)
      }
  }
  
  func delete(req: Request) throws -> EventLoopFuture<Response> {
    let redirect = req.redirect(to: "/app/news")
    
    return Article.find(req.parameters.get("article"), on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { article in
        return article.delete(on: req.db).transform(to: redirect)
      }
  }
}
