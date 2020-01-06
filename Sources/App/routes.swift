import Vapor

/// Register your application's routes here.
public func routes(_ router: Router, awsConfig: AwsConfig) throws {
  let awsController = AwsController(awsConfig: awsConfig)
  try router.register(collection: awsController)
  
  let userController = UserController()
  try router.register(collection: userController)
  
  let appController = AppController()
  try router.register(collection: appController)
  
  let artistController = ArtistController(awsController: awsController)
  try router.register(collection: artistController)
  
  let eventController = EventController()
  try router.register(collection: eventController)
  
  let releaseController = ReleaseController()
  try router.register(collection: releaseController)
  
  let interviewController = InterviewController()
  try router.register(collection: interviewController)
  
  let articleController = ArticleController()
  try router.register(collection: articleController)
  
  let publicController = PublicController()
  try router.register(collection: publicController)
}
