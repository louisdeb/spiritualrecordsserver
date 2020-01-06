//
//  String+ReplaceOccurances.swift
//  App
//
//  Created by Louis de Beaumont on 06/01/2020.
//

import Foundation

extension String {
  /// Replace all occurances of regex pattern with another string
  public mutating func replaceOccurances(pattern: String, with: String) {
    do {
      let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
      let range = NSMakeRange(0, self.count)
      self = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: with)
    } catch {
      return
    }
  }
}
