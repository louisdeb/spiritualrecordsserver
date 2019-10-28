//
//  Date+NextDay.swift
//  App
//
//  Created by Louis de Beaumont on 07/10/2019.
//

import Vapor

extension Date {
  public func previous(_ weekday: Weekday) ->  Date {
    let calendar = Calendar(identifier: .gregorian)
    let components = DateComponents(hour: 1, minute: 0, second: 0,
                                    weekday: weekday.rawValue)
    
    if calendar.component(.weekday, from: self) == weekday.rawValue {
      return self
    }
    
    return calendar.nextDate(after: self,
                             matching: components,
                             matchingPolicy: .strict,
                             direction: .backward)!
  }
}

public enum Weekday: Int {
  case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
}
