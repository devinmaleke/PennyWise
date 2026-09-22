//
//  FirestoreValue.swift
//  PennyWise
//
//  Created by Devin Maleke on 19/01/26.
//

import Foundation

enum FirestoreValue {

    static func int(_ value: Any?) -> Int? {
        if let intValue = value as? Int {
            return intValue
        }
        if let int64Value = value as? Int64 {
            return Int(int64Value)
        }
        if let doubleValue = value as? Double {
            return Int(doubleValue)
        }
        if let number = value as? NSNumber {
            return number.intValue
        }
        if let string = value as? String {
            let cleaned = string
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return Int(cleaned)
        }
        return nil
    }
}
