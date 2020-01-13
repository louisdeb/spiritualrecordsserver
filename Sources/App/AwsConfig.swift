//
//  AwsConfig.swift
//  App
//
//  Created by Louis de Beaumont on 17/12/2019.
//

// https://fivedottwelve.com/blog/using-amazon-s3-with-vapor/

import Vapor
import VaporExt
import S3

public struct AwsConfig {
  var url: String
  var uploadPath: String
  var name: String
  var accKey: String
  var secKey: String
  var region: Region
}

class AwsConfiguration {
  
  func setup(services: inout Services) throws -> AwsConfig {
    guard
      let url: String = Environment.get(Keys.url),
      let uploadPath: String = Environment.get(Keys.uploadPath),
      let name: String = Environment.get(Keys.name),
      let accKey: String = Environment.get(Keys.accKey),
      let secKey: String = Environment.get(Keys.secKey),
      let regionString: String = Environment.get(Keys.region)
    else {
      throw CreateError.runtimeError("Missing environment value for aws config")
    }
    
    let region = Region(name: Region.Name.init(regionString))
    
    let config = AwsConfig(
      url: url,
      uploadPath: uploadPath,
      name: name,
      accKey: accKey,
      secKey: secKey,
      region: region
    )
    
    let s3Config = S3Signer.Config(
      accessKey: accKey,
      secretKey: secKey,
      region: region
    )
    
    try services.register(
      s3: s3Config,
      defaultBucket: name
    )
    
    return config
  }
}

private extension AwsConfiguration {
  struct Keys {
    private init() {}
    
    static let url = "BUCKET_URL"
    static let uploadPath = "BUCKET_UPLOADPATH"
    static let name = "BUCKET_NAME"
    static let accKey = "BUCKET_ACCKEY"
    static let secKey = "BUCKET_SECKEY"
    static let region = "BUCKET_REGION"
  }
}
