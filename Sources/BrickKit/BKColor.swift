//
//  File.swift
//  BrickKit
//
//  Created by iain on 28/02/2025.
//

#if os(macOS)
import AppKit
#elseif os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
import UIKit
#endif

import Foundation

public typealias BKColorCode = UInt16

#if os(macOS)
public typealias BKNativeColor = NSColor
#elseif os(iOS)
public typealias BKNativeColor = UIColor
#endif

public enum BKFinish {
    case chrome
    case pearlescent
    case rubber
    case matte
    case metallic
    case material
}

public struct BKColor {
    public let name: String
    public var code: BKColorCode = 0
    public var color: BKNativeColor = .black
    public var edgeColor: BKNativeColor?
    public var edgeCode: BKColorCode?
    public var alpha: UInt8 = 255
    public var luminosity: UInt8 = 0
    
    public var finish: BKFinish?
    
    public init?(from line: String) {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = trimmedLine.split(separator: " ")
        
        if components.count < 9 {
            return nil
        }
        
        if components[0] != "0" || components[1] != "!COLOUR" {
            return nil
        }
        
        name = String(components[2])
        
        var index = 3
        while index < components.count {
            switch components[index] {
            case "CODE":
                code = BKColorCode(String(components[index + 1])) ?? 0
                index += 2
                break
                
            case "VALUE":
                let hex = String(components[index + 1])
                color = .init(fromHex: hex) ?? .gray
                index += 2
                break
                
            case "EDGE":
                edgeCode = BKColorCode(String(components[index + 1]))
                if edgeCode == nil {
                    let hex = String(components[index + 1])
                    edgeColor = .init(fromHex: hex)
                }
                index += 2
                break
                
            case "ALPHA":
                alpha = UInt8(String(components[index + 1])) ?? 255
                color = color.withAlphaComponent(CGFloat(alpha) / 255.0)
                index += 2
                break
                
            case "LUMINANCE":
                luminosity = UInt8(String(components[index + 1])) ?? 0
                index += 2
                break
                
            case "CHROME":
                finish = .chrome
                index = .max
                break
                
            case "PEARLESCENT":
                finish = .pearlescent
                index = .max
                break
                
            case "RUBBER":
                finish = .rubber
                index = .max
                break
                
            case "MATTE_METALLIC":
                finish = .matte
                index = .max
                break
                
            case "METAL":
                finish = .metallic
                index = .max
                break
                
            case "MATERIAL":
                finish = .material
                index = .max
                break
                
            default:
                index += 1
                break
            }
        }
    }
}

fileprivate extension BKNativeColor {
    convenience init?(fromHex hexColor: String, alpha: CGFloat = 1.0) {
        var colorCode : UInt32 = 0

        var hex: String = hexColor
        if hexColor.hasPrefix("#") {
            hex = String(hexColor[hexColor.index(hexColor.startIndex, offsetBy: 1)...])
        } else {
            hex = hexColor
        }

        let scanner = Scanner(string: hex)
        let success = scanner.scanHexInt32(&colorCode)

        if !success {
            return nil
        }

        let redByte = (colorCode >> 16) & 0xFF
        let greenByte = (colorCode >> 8) & 0xFF
        let blueByte = colorCode & 0xFF
        
#if os(macOS)
        self.init(calibratedRed: CGFloat(redByte) / 256.0,
                  green: CGFloat(greenByte) / 256.0,
                  blue: CGFloat(blueByte) / 256.0,
                  alpha: alpha)
#elseif os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
        self.init(red: CGFloat(redByte) / 256.0,
                  green: CGFloat(greenByte) / 256.0,
                  blue: CGFloat(blueByte) / 256.0,
                  alpha: alpha)
#endif
    }
}
