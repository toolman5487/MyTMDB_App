//
//  UIColorExtension.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/28.
//

import Foundation
import UIKit

extension UIColor {
    convenience init?(hex: String, alpha: CGFloat = 1.0) {
        let cleaned = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "0X", with: "")

        let rgb: (r: Int, g: Int, b: Int, a: Int)

        switch cleaned.count {
        case 3:
            func expand(_ c: Character) -> String { String(String(c)) + String(String(c)) }
            let chars = Array(cleaned)
            let rStr = expand(chars[0])
            let gStr = expand(chars[1])
            let bStr = expand(chars[2])

            guard
                let r = Int(rStr, radix: 16),
                let g = Int(gStr, radix: 16),
                let b = Int(bStr, radix: 16)
            else { return nil }
            rgb = (r, g, b, 255)

        case 6:
            guard
                let r = Int(cleaned.prefix(2), radix: 16),
                let g = Int(cleaned.dropFirst(2).prefix(2), radix: 16),
                let b = Int(cleaned.dropFirst(4).prefix(2), radix: 16)
            else { return nil }
            rgb = (r, g, b, 255)

        case 8:
            guard
                let r = Int(cleaned.prefix(2), radix: 16),
                let g = Int(cleaned.dropFirst(2).prefix(2), radix: 16),
                let b = Int(cleaned.dropFirst(4).prefix(2), radix: 16),
                let a = Int(cleaned.dropFirst(6).prefix(2), radix: 16)
            else { return nil }
            rgb = (r, g, b, a)

        default:
            return nil
        }

        let resolvedAlpha = CGFloat(rgb.a) / 255.0
        let finalAlpha = cleaned.count == 8 ? resolvedAlpha : alpha

        self.init(
            red: CGFloat(rgb.r) / 255.0,
            green: CGFloat(rgb.g) / 255.0,
            blue: CGFloat(rgb.b) / 255.0,
            alpha: finalAlpha
        )
    }
}
