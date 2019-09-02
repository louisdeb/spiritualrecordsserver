import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "It works" example
    router.get { req in
        return "It works!"
    }
    
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }
  
  router.get("view") { req -> Future<View> in
    return try req.view().render("welcome")
  }
  
  let appController = AppController()
  try router.register(collection: appController)
  
  let artistController = ArtistController()
  try router.register(collection: artistController)
  
  let eventController = EventController()
  try router.register(collection: eventController)
}
