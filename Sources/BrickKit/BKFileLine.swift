//
//  File.swift
//  BrickKit
//
//  Created by iain on 17/02/2025.
//

import Foundation
import SceneKit

enum BKMeta : Sendable{
    case fileWinding(WindingRule)
    case invertNextInstruction
    case clip(Bool, WindingRule)
    case certified(Bool, WindingRule)
    case ignore
    
    static func from(string: String) -> Self {
        let components = string.components(separatedBy: " ")

        let componentCount = components.count
        
        if componentCount > 2 {
            if components[1] == "BFC" {
                if components[2] == "INVERTNEXT" {
                    return .invertNextInstruction
                } else if components[2] == "CCW" {
                    return .fileWinding(.CCW)
                } else if components[2] == "CW" {
                    return .fileWinding(.CW)
                } else if components[2] == "CERTIFY" {
                    if componentCount == 3 {
                        return .certified(true, .CCW)
                    } else if components[3] == "CCW" {
                        return .certified(true, .CCW)
                    } else if components[3] == "CW" {
                        return .certified(true, .CW)
                    }
                } else if components[2] == "NOCERTIFY" {
                    return .certified(false, .CCW)
                } else if components[2] == "NOCLIP" {
                    return .clip(false, .CCW)
                } else if components[2] == "CLIP" {
                    if componentCount == 3 {
                        return .clip(true, .CCW)
                    } else if components[3] == "CCW" {
                        if componentCount == 4 {
                            return .clip(true, .CCW)
                        } else {
                            return .clip(true, .CW)
                        }
                    }
                }
            }
        }
        
        return .ignore
    }
}

struct BKSubpart {
    let colour: Int32
    let transform: SCNMatrix4
    
    let filename: String

    init(from string: String) {
        let components = string.components(separatedBy: " ")
        
        colour = Int32(components[1]) ?? 16
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
    let colour: Int32
    
    let v1: SCNVector3
    let v2: SCNVector3
    
    init(from string: String) {
        let components = string.components(separatedBy: " ")
        
        colour = Int32(components[1]) ?? 16
        v1 = SCNVector3(xStr: components[2],
                        yStr: components[3],
                        zStr: components[4]) ?? SCNVector3Zero
        v2 = SCNVector3(xStr: components[5],
                        yStr: components[6],
                        zStr: components[7]) ?? SCNVector3Zero
    }
}

struct BKTriangle {
    let colour: Int32
    
    let v1: SCNVector3
    let v2: SCNVector3
    let v3: SCNVector3
    
    init(from string: String) {
        let components = string.components(separatedBy: " ")
        
        colour = Int32(components[1]) ?? 16
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
    let colour: Int32
    
    let v1: SCNVector3
    let v2: SCNVector3
    let v3: SCNVector3
    let v4: SCNVector3
    
    init(from string: String) {
        let components = string.components(separatedBy: " ")
        
        colour = Int32(components[1]) ?? 16
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
    let colour: Int32
    
    let v1: SCNVector3
    let v2: SCNVector3
    let control1: SCNVector3
    let control2: SCNVector3
    
    init(from string: String) {
        let components = string.components(separatedBy: " ")
        
        colour = Int32(components[1]) ?? 16
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

enum BFCCommand: Sendable {
    case certify
    case nocertify
    case ccw
    case cw
    case invertnext
    case clip
    case noclip
}

enum BKFileLine: Sendable {
    case meta(BKMeta) // 0
    case bfc([BFCCommand]) // 0 BFC
    
    case subpart(BKSubpart, BKPart) // 1
    
    case line(BKLine) // 2
    case triangle(BKTriangle) // 3
    case rectangle(BKRectangle) // 4
    
    case optionalLine(BKOptionalLine)// 5
    case end // X special addition for debugging
}
