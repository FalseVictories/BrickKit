//
//  File.swift
//  BrickKit
//
//  Created by iain on 17/02/2025.
//

import Foundation
import SceneKit

enum BKMeta {
    case invertNextInstruction
    case ignore
    
    static func from(string: String) -> Self {
        let components = string.components(separatedBy: " ")

        if components.count > 2 {
            if components[1] == "BFC" && components[2] == "INVERTNEXT" {
                return .invertNextInstruction
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
        
        transform = SCNMatrix4(m11: t1.x, m12: t1.y, m13: t1.z, m14: 0,
                               m21: t2.x, m22: t2.y, m23: t2.z, m24: 0,
                               m31: t3.x, m32: t3.y, m33: t3.z, m34: 0,
                               m41: position.x, m42: position.y, m43: position.z, m44: 1)
        filename = components[14]
    }
}

struct BKLine {
    let colour: Int32
    
    let v1: SCNVector3
    let v2: SCNVector3
    
    init(from string: String) {
        let components = string.components(separatedBy: " ")
        
        colour = Int32(components[1]) ?? 16
        v1 = SCNVector3(xStr: components[2], yStr: components[3], zStr: components[4]) ?? SCNVector3Zero
        v2 = SCNVector3(xStr: components[5], yStr: components[6], zStr: components[7]) ?? SCNVector3Zero
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
        v1 = SCNVector3(xStr: components[2], yStr: components[3], zStr: components[4]) ?? SCNVector3Zero
        v2 = SCNVector3(xStr: components[5], yStr: components[6], zStr: components[7]) ?? SCNVector3Zero
        v3 = SCNVector3(xStr: components[8], yStr: components[9], zStr: components[10]) ?? SCNVector3Zero
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
        v1 = SCNVector3(xStr: components[2], yStr: components[3], zStr: components[4]) ?? SCNVector3Zero
        v2 = SCNVector3(xStr: components[5], yStr: components[6], zStr: components[7]) ?? SCNVector3Zero
        v3 = SCNVector3(xStr: components[8], yStr: components[9], zStr: components[10]) ?? SCNVector3Zero
        v4 = SCNVector3(xStr: components[11], yStr: components[12], zStr: components[13]) ?? SCNVector3Zero
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
        v1 = SCNVector3(xStr: components[2], yStr: components[3], zStr: components[4]) ?? SCNVector3Zero
        v2 = SCNVector3(xStr: components[5], yStr: components[6], zStr: components[7]) ?? SCNVector3Zero
        control1 = SCNVector3(xStr: components[8], yStr: components[9], zStr: components[10]) ?? SCNVector3Zero
        control2 = SCNVector3(xStr: components[11], yStr: components[12], zStr: components[13]) ?? SCNVector3Zero
    }
}

enum BKFileLine {
    case meta(BKMeta) // 0
    case subpart(BKSubpart, BKPart) // 1
    
    case line(BKLine) // 2
    case triangle(BKTriangle) // 3
    case rectangle(BKRectangle) // 4
    
    case optionalLine(BKOptionalLine)// 5
}
