import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
  let appController = AppController()
  try router.register(collection: appController)
  
  let artistController = ArtistController()
  try router.register(collection: artistController)
  
  let eventController = EventController()
  try router.register(collection: eventController)
  
  let releaseController = ReleaseController()
  try router.register(collection: releaseController)
}
