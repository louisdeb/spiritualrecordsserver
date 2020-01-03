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
  
  /* Database configs
  
  let psqlDbConfig_local = PostgreSQLDatabaseConfig(
    hostname: "localhost",
    port: 5432,
    username: "vapor",
    password: "password",
    transport: .cleartext
  )
  
  let vaporCloudProductionDbConfig = PostgreSQLDatabaseConfig(
    hostname: "database.v2.vapor.cloud",
    port: 30001,
    username: "u05ea553463603193de60b74879e2763",
    database: "d06638f79d3c10da",
    password: "pc627f79f8bbedd7e4663a7a9552c1e5"
  )
  
  */
  
  let herokuProductionDbConfig = PostgreSQLDatabaseConfig(
    hostname: "ec2-46-137-173-221.eu-west-1.compute.amazonaws.com",
    port: 5432,
    username: "miglxvpjfulovg",
    database: "d39tk4qt8fctll",
    password: "588bfbc3bbd50c4bdc143c8e6f42ab2eb6b2be07b42e2c28c636d0f0b8557c0f"
  )

  let psql = PostgreSQLDatabase(config: herokuProductionDbConfig)

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
