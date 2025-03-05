//
//  File.swift
//  BrickKit
//
//  Created by iain on 17/02/2025.
//

import Foundation
import SceneKit

enum BFCCommand: Sendable {
    case certify
    case nocertify
    case ccw
    case cw
    case invertnext
    case clip
    case noclip
}

enum BKMeta : Sendable{
    case bfc([BFCCommand])
    case ignore
    
    static func from(string: String) -> Self {
        let components = string.components(separatedBy: " ")

        let componentCount = components.count
        
        if componentCount > 2 {
            if components[1] == "BFC" {
                var bfcCommands = [BFCCommand]()
                for i in 2..<componentCount {
                    switch components[i] {
                    case "CLIP":
                        bfcCommands.append(.clip)
                    case "NOCLIP":
                        bfcCommands.append(.noclip)
                    case "INVERTNEXT":
                        bfcCommands.append(.invertnext)
                    case "CCW":
                        bfcCommands.append(.ccw)
                    case "CW":
                        bfcCommands.append(.cw)
                    case "CERTIFY":
                        bfcCommands.append(.certify)
                    case "NOCERTIFY":
                        bfcCommands.append(.nocertify)
                    default:
                        break
                    }
                }
                
                return .bfc(bfcCommands)
            }
        }
        
        return .ignore
    }
}

struct BKSubpart {
    let color: UInt16
    let transform: SCNMatrix4
    
    let filename: String

    init?(from string: String) {
        let components = string.components(separatedBy: " ")
        
        if components.count != 15 {
            return nil
        }
        
        color = UInt16(components[1]) ?? 16
        let position = SCNVector3(xStr: components[2], yStr: components[3], zStr: components[4]) ?? SCNVector3Zero
        let t1 = SCNVector3(xStr: components[5], yStr: components[6], zStr: components[7]) ?? SCNVector3Zero
        let t2 = SCNVector3(xStr: components[8], yStr: components[9], zStr: components[10]) ?? SCNVector3Zero
        let t3 = SCNVector3(xStr: components[11], yStr: components[12], zStr: components[13]) ?? SCNVector3Zero
        
        transform = SCNMatrix4(m11: t1.x, m12: t2.x, m13: t3.x, m14: 0,
                               m21: t1.y, m22: t2.y, m23: t3.y, m24: 0,
                               m31: t1.z, m32: t2.z, m33: t3.z, m34: 0,
                               m41: position.x, m42: position.y, m43: position.z, m44: 1)
        filename = components[14].replacingOccurrences(of: "\\", with: "/")
    }
}

struct BKLine {
    let color: UInt16
    
    let v1: SCNVector3
    let v2: SCNVector3
    
    init?(from string: String) {
        let components = string.components(separatedBy: " ")
        
        if components.count != 8 {
            return nil
        }
        
        color = UInt16(components[1]) ?? 16
        v1 = SCNVector3(xStr: components[2],
                        yStr: components[3],
                        zStr: components[4]) ?? SCNVector3Zero
        v2 = SCNVector3(xStr: components[5],
                        yStr: components[6],
                        zStr: components[7]) ?? SCNVector3Zero
    }
}

struct BKTriangle {
    let color: UInt16
    
    let v1: SCNVector3
    let v2: SCNVector3
    let v3: SCNVector3
    
    init?(from string: String) {
        let components = string.components(separatedBy: " ")
        
        if components.count != 11 {
            return nil
        }
        
        color = UInt16(components[1]) ?? 16
        v1 = SCNVector3(xStr: components[2],
                        yStr: components[3],
                        zStr: components[4]) ?? SCNVector3Zero
        v2 = SCNVector3(xStr: components[5],
                        yStr: components[6],
                        zStr: components[7]) ?? SCNVector3Zero
        v3 = SCNVector3(xStr: components[8],
                        yStr: components[9],
                        zStr: components[10]) ?? SCNVector3Zero
    }
}

struct BKRectangle {
    let color: UInt16
    
    let v1: SCNVector3
    let v2: SCNVector3
    let v3: SCNVector3
    let v4: SCNVector3
    
    init?(from string: String) {
        let components = string.components(separatedBy: " ")
        
        if components.count != 14 {
            return nil
        }
        
        color = UInt16(components[1]) ?? 16
        v1 = SCNVector3(xStr: components[2],
                        yStr: components[3],
                        zStr: components[4]) ?? SCNVector3Zero
        v2 = SCNVector3(xStr: components[5],
                        yStr: components[6],
                        zStr: components[7]) ?? SCNVector3Zero
        v3 = SCNVector3(xStr: components[8],
                        yStr: components[9],
                        zStr: components[10]) ?? SCNVector3Zero
        v4 = SCNVector3(xStr: components[11],
                        yStr: components[12],
                        zStr: components[13]) ?? SCNVector3Zero
    }
}

struct BKOptionalLine {
    let color: UInt16
    
    let v1: SCNVector3
    let v2: SCNVector3
    let control1: SCNVector3
    let control2: SCNVector3
    
    init?(from string: String) {
        let components = string.components(separatedBy: " ")
        
        if components.count != 14 {
            return nil
        }
        
        color = UInt16(components[1]) ?? 16
        v1 = SCNVector3(xStr: components[2],
                        yStr: components[3],
                        zStr: components[4]) ?? SCNVector3Zero
        v2 = SCNVector3(xStr: components[5],
                        yStr: components[6],
                        zStr: components[7]) ?? SCNVector3Zero
        control1 = SCNVector3(xStr: components[8],
                              yStr: components[9],
                              zStr: components[10]) ?? SCNVector3Zero
        control2 = SCNVector3(xStr: components[11],
                              yStr: components[12],
                              zStr: components[13]) ?? SCNVector3Zero
    }
}

enum BKFileLine: Sendable {
    case meta(BKMeta) // 0
    
    case subpart(BKSubpart, BKPart) // 1
    
    case line(BKLine) // 2
    case triangle(BKTriangle) // 3
    case rectangle(BKRectangle) // 4
    
    case optionalLine(BKOptionalLine)// 5
    case end // X special addition for debugging
}
