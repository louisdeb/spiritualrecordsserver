import FluentPostgreSQL
import Vapor
import Authentication
import Leaf

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
  // Register providers first
  try services.register(FluentPostgreSQLProvider())
  try services.register(AuthenticationProvider())
  try services.register(LeafProvider())
  
  config.prefer(LeafRenderer.self, for: ViewRenderer.self)
  config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)

  // Register routes to the router
  let router = EngineRouter.default()
  try routes(router)
  services.register(router, as: Router.self)

  // Register middleware
  var middlewares = MiddlewareConfig() // Create _empty_ middleware config
  middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
  middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
  middlewares.use(SessionsMiddleware.self) // Provides cookies for persistent web authentication
  services.register(middlewares)

  let psqlConfig: PostgreSQLDatabaseConfig
  
  if let url = Environment.get("DATABASE_URL") {
    psqlConfig = PostgreSQLDatabaseConfig(url: url)!
  } else {
    psqlConfig = PostgreSQLDatabaseConfig(hostname: "localhost", username: "app_collection")
  }

  let psql = PostgreSQLDatabase(config: psqlConfig)

  var databases = DatabasesConfig()
  databases.add(database: psql, as: .psql)
  databases.enableLogging(on: .psql)
  services.register(databases)

  var migrations = MigrationConfig()
  
  // Models
  migrations.add(model: User.self, database: .psql)
  migrations.add(model: Artist.self, database: .psql)
  migrations.add(model: Event.self, database: .psql)
  migrations.add(model: Release.self, database: .psql)
  migrations.add(model: Interview.self, database: .psql)
  migrations.add(model: Article.self, database: .psql)
  migrations.add(model: ArtistEventPivot.self, database: .psql)
  migrations.add(model: ArtistReleasePivot.self, database: .psql)
  migrations.add(model: ArtistInterviewPivot.self, database: .psql)
  
  // Migrations
  migrations.add(migration: AddImageToInterview.self, database: .psql)
  migrations.add(migration: AddTicketsURLToEvent.self, database: .psql)
  
  services.register(migrations)
}
