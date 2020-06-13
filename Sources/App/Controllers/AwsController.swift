//
//  AwsController.swift
//  App
//
//  Created by Louis de Beaumont on 17/12/2019.
//

import Vapor
import S3
/*
final class AwsController: RouteCollection {
  let awsConfig: AwsConfig
  
  init(awsConfig: AwsConfig) {
    self.awsConfig = awsConfig
  }
  
  func boot(routes: RoutesBuilder) throws {
    let route = routes.grouped("api", "aws")
    
    route.post(ImageResponse.self, at: "s3-image-created", use: imageCreatedCallback)
    
    let auth = route.grouped([
      User.sessionAuthenticator(),
      // redirect middleware
    ])

    auth.get(use: preparePresignedUrlForImage)
  }
  
  func preparePresignedUrlForImage(req: Request) throws -> PresignedURL {
    let baseUrl = awsConfig.url
    let uploadPath = awsConfig.uploadPath
    let newFilename = UUID().uuidString + ".jpg"
    
    guard var url = URL(string: baseUrl) else {
      throw Abort(.internalServerError)
    }
    
    url.appendPathComponent(uploadPath)
    url.appendPathComponent(newFilename)
    
    let headers = ["x-amz-acl": "public-read"]
    let s3 = try req.makeS3Signer()
    let result = try s3.presignedURL(for: .PUT, url: url, expiration: Expiration.hour, headers: headers)
    
    guard let presignedUrl = result?.absoluteString else {
      throw Abort(.internalServerError)
    }
    
    return PresignedURL(url: presignedUrl, get: baseUrl + uploadPath + newFilename)
  }
  
  func imageCreatedCallback(request: Request, response: ImageResponse) throws -> HTTPResponseStatus {
    print("image created callback")
    print(response.filename)
    return .ok
  }
}

struct ImageResponse: Content {
  var filename: String
}

struct PresignedURL: Content {
  var url: String
  var get: String
}
*/
