//
//  BlockSchedule.swift
//  ScreenTimeAPIExample
//
//  Created by Giorgio Gunawan on 13/11/2024.
//

import Foundation

public struct BlockSchedule: Codable, Identifiable {
    public let id: UUID
    public let startHour: Int
    public let startMinute: Int
    public let endHour: Int
    public let endMinute: Int
    public var isActive: Bool
    
    public init(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int, isActive: Bool = true) {
        self.id = UUID()
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.isActive = isActive
    }
    
    public func formattedStartTime() -> String {
        return String(format: "%02d:%02d", startHour, startMinute)
    }
    
    public func formattedEndTime() -> String {
        return String(format: "%02d:%02d", endHour, endMinute)
    }
}
