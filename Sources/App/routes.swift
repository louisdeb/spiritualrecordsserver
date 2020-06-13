import Vapor

public func routes(app: Application) throws { // awsConfig parameter removed
//  try app.register(collection: AwsController(awsConfig: awsConfig))
  try app.register(collection: UserController())
  try app.register(collection: AppController())
  try app.register(collection: ArtistController())
  try app.register(collection: EventController())
  try app.register(collection: ReleaseController())
  try app.register(collection: InterviewController())
  try app.register(collection: ArticleController())
  try app.register(collection: PublicController())
  
  app.logger.info("Routes registered")
}
