//
//  Keycode.swift
//  Satin
//
//  Created by Philip Isakson on 2025-05-25.
//

import Foundation

class Keycode {
    
    static let dictionary: [String : UInt16] = [
        "A": 0,
        "B": 11,
        "C": 8,
        "D": 2,
        "E": 14,
        "F": 3,
        "G": 5,
        "H": 4,
        "I": 34,
        "J": 38,
        "K": 40,
        "L": 37,
        "M": 46,
        "N": 45,
        "O": 31,
        "P": 35,
        "Q": 12,
        "R": 15,
        "S": 1,
        "T": 17,
        "U": 32,
        "V": 9,
        "W": 13,
        "X": 7,
        "Y": 16,
        "Z": 6
    ]

    
    static func get(key: String) -> UInt16?{
        return dictionary.first{
            (letter, keyode) in letter == key.uppercased(with: .autoupdatingCurrent)
        }?.value
        
    }
}
