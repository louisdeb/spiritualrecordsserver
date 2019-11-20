//
//  Errors.swift
//  App
//
//  Created by Louis de Beaumont on 20/11/2019.
//

import Foundation

enum CreateError: Error {
  case runtimeError(String)
}

enum GetError: Error {
  case runtimeError(String)
}
