//
//  BlockSchedule.swift
//  ScreenTimeAPIExample
//
//  Created by Giorgio Gunawan on 13/11/2024.
//

import Foundation

public struct BlockSchedule: Codable, Identifiable, Hashable {
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

    // Implementing Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(startHour)
        hasher.combine(startMinute)
        hasher.combine(endHour)
        hasher.combine(endMinute)
    }

    public static func == (lhs: BlockSchedule, rhs: BlockSchedule) -> Bool {
        return lhs.id == rhs.id &&
               lhs.startHour == rhs.startHour &&
               lhs.startMinute == rhs.startMinute &&
               lhs.endHour == rhs.endHour &&
               lhs.endMinute == rhs.endMinute
    }
}
