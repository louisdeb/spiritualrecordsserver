import Vapor
import Fluent
import FluentPostgresDriver
import Leaf

/// Called before your application initializes.
public func configure(_ app: Application) throws {
  
  app.sessions.use(.fluent)
  
//  let awsConfig = try AwsConfiguration().setup(services: &services)
//  try routes(app, awsConfig: awsConfig)
  
  app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
  app.middleware.use(ErrorMiddleware.default(environment: app.environment))
  app.middleware.use(app.sessions.middleware)
  
  app.views.use(.leaf)
  app.leaf.cache.isEnabled = false // app.environment.isRelease
  
  if let url: String = Environment.get("DATABASE_URL") {
    try app.databases.use(.postgres(url: url), as: .psql)
  } else {
    app.databases.use(.postgres(hostname: "localhost", username: "louis", password: "password"), as: .psql)
  }
  
//  services.register(NIOServerConfig.default(workerCount: 4))
//  services.register(DatabaseConnectionPoolConfig(maxConnections: 4))
  
  app.migrations.add(SessionRecord.migration)
  
  app.migrations.add(User.Create())
  app.migrations.add(Artist.Create())
  app.migrations.add(Event.Create())
  app.migrations.add(Release.Create())
  app.migrations.add(Interview.Create())
  app.migrations.add(Article.Create())
  app.migrations.add(Image.Create())
  app.migrations.add(ArtistEvent.Create())
  app.migrations.add(ArtistRelease.Create())
  app.migrations.add(ArtistInterview.Create())
  app.migrations.add(ArtistImage.Create())
  app.migrations.add(ReleaseImage.Create())
  
  try routes(app: app)
  
  app.logger.info("App config complete")
}
