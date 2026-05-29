//
//  Extensions.swift
//  Prysm
//

import Foundation

// MARK: - Safe Array Subscript (defined once, used everywhere)
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
