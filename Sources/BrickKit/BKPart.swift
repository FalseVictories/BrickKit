//
//  BKPart.swift
//  BrickKit
//
//  Created by iain on 17/02/2025.
//

import Foundation
import SceneKit

enum WindingRule {
    case CCW
    case CW
    
    func toggle() -> Self {
        self == .CCW ? .CW : .CCW
    }
}

class GeometryBuilderCollection {
    var builders: [BKColorCode: GeometryBuilder] = [:]
    
    func builderForColor(_ color: BKColorCode) -> GeometryBuilder {
        if let existingBuilder = builders[color] {
            return existingBuilder
        } else {
            let newBuilder = GeometryBuilder()
            builders[color] = newBuilder
            return newBuilder
        }
    }
}

class GeometryBuilder {
    var lineVerticies: [SCNVector3] = []
    var lineIndices: [Int] = []
    var lineCount = 0
    
    var triangleVerticies: [SCNVector3] = []
    var triangleIndices: [Int] = []
    var triangleCount = 0
    
    func addLine(from: SCNVector3, to: SCNVector3) {
        lineVerticies.append(contentsOf: [from, to])
        lineIndices.append(contentsOf: [lineCount, lineCount + 1])
        lineCount += 2
    }
    
    // Does not consider winding rules, caller must order the vertices accordingly
    func addTriangle(vertex1: SCNVector3, vertex2: SCNVector3, vertex3: SCNVector3) {
        triangleVerticies.append(contentsOf: [vertex1, vertex2, vertex3])
        triangleIndices.append(contentsOf: [triangleCount,
                                            triangleCount + 1,
                                            triangleCount + 2])
        triangleCount += 3
    }
    
    func splitToMaxTriangles() -> ([[SCNVector3]], [[UInt16]]) {
        var triangles: [[SCNVector3]] = []
        var indices: [[UInt16]] = []
        
        var currentTriangles: [SCNVector3] = []
        var currentIndices: [UInt16] = []
        var index = 0
        var uintIndex = 0
        
        while index < triangleCount {
            currentTriangles.append(triangleVerticies[index])
            currentIndices.append(UInt16(triangleIndices[uintIndex]))
            
            index += 1

            if index >= 65536 {
                triangles.append(currentTriangles)
                indices.append(currentIndices)
                currentTriangles = []
                currentIndices = []
                uintIndex = 0
            } else {
                uintIndex += 1
            }
        }
        
        if !currentTriangles.isEmpty {
            triangles.append(currentTriangles)
        }
        
        if !currentIndices.isEmpty {
            indices.append(currentIndices)
        }
        
        return (triangles, indices)
    }
    
    func splitToMaxLines() -> ([[SCNVector3]], [[UInt16]]) {
        var lines: [[SCNVector3]] = []
        var indices: [[UInt16]] = []
        
        var currentLines: [SCNVector3] = []
        var currentIndices: [UInt16] = []
        var index = 0
        var uintIndex = 0
        
        while index < lineCount {
            currentLines.append(lineVerticies[index])
            currentIndices.append(UInt16(lineIndices[uintIndex]))
            
            index += 1
            
            // Want max 65534 per group
            if index >= 65535 {
                lines.append(currentLines)
                indices.append(currentIndices)
                currentLines = []
                currentIndices = []
                uintIndex = 0
            } else {
                uintIndex += 1
            }
        }
        
        if !currentLines.isEmpty {
            lines.append(currentLines)
        }
        
        if !currentIndices.isEmpty {
            indices.append(currentIndices)
        }
        
        return (lines, indices)
    }
}

public struct BKPart: Sendable {
    public let color: BKColorCode
    let filename: String
    let lines: [BKFileLine]
    
    @MainActor
    public func toNode(inverted: Bool = false,
                       transform: SCNMatrix4 = SCNMatrix4Identity) -> BKPartNode {
        let builderCollection = GeometryBuilderCollection()
        
        var geometryBuilder = GeometryBuilder()
        var contrastingGeoBuilder = GeometryBuilder()
        
        builderCollection.builders[16] = geometryBuilder
        builderCollection.builders[24] = contrastingGeoBuilder
        
        return toNode(inverted: inverted,
                      transform: transform,
                      geometryBuilders: builderCollection,
                      currentColor: 16)
    }
    
    @MainActor
    func toNode(inverted: Bool = false,
                transform: SCNMatrix4 = SCNMatrix4Identity,
                geometryBuilders: GeometryBuilderCollection,
                currentColor: BKColorCode) -> BKPartNode {
        
        buildGeometry(inverted: inverted,
                      transform: transform,
                      geometryBuilders: geometryBuilders,
                      currentColor: 16)
        
        let node = BKPartNode(colorBuilders: geometryBuilders)
        node.name = filename
        
        return node
    }
    
}

private extension BKPart {
    func buildGeometry(inverted: Bool = false,
                       transform: SCNMatrix4 = SCNMatrix4Identity,
                       geometryBuilders: GeometryBuilderCollection,
                       currentColor: BKColorCode) {
        var partWinding = WindingRule.CCW
        var currentWinding = WindingRule.CCW
        var invertNext = false
        let determinantFlip = transform.determinant < 0
                
        for line in lines {
            switch line {
            case .end:
                return

            case .subpart(let subpart, let part):
                let realColor = subpart.color == 16 ? currentColor : subpart.color
                part.buildGeometry(inverted: inverted ^ invertNext,
                                   transform: SCNMatrix4Mult(subpart.transform, transform),
                                   geometryBuilders: geometryBuilders,
                                   currentColor: realColor)
                invertNext = false
                break

            case .meta(let meta):
                switch meta {
                case .ignore:
                    break
                    
                case .bfc(let bfcCommands):
                    for command in bfcCommands {
                        switch command {
                        case .invertnext:
                            invertNext = true
                        case .ccw:
                            partWinding = .CCW
                            currentWinding = inverted ? .CW : .CCW
                        case .cw:
                            partWinding = .CW
                            currentWinding = inverted ? .CCW : .CW
                        case .certify, .noclip, .clip, .nocertify:
                            break
                        }
                    }
                }
                break
                
            case .line(let line):
                let v1 = line.v1.multiply(by: transform)
                let v2 = line.v2.multiply(by: transform)
                
                let realColor = line.color == 16 ? currentColor : line.color
                let currentBuilder = geometryBuilders.builderForColor(realColor)
                currentBuilder.addLine(from: v1, to: v2)
                
                invertNext = false
                break
                
            case .triangle(let triangle):
                let v1 = triangle.v1.multiply(by: transform)
                let v2 = triangle.v2.multiply(by: transform)
                let v3 = triangle.v3.multiply(by: transform)
                
                var winding = currentWinding
                if determinantFlip {
                    winding = winding.toggle()
                }

                let realColor = triangle.color == 16 ? currentColor : triangle.color
                let currentBuilder = geometryBuilders.builderForColor(realColor)
                if winding == partWinding {
                    currentBuilder.addTriangle(vertex1: v1, vertex2: v2, vertex3: v3)
                } else {
                    currentBuilder.addTriangle(vertex1: v3, vertex2: v2, vertex3: v1)
                }
                
                invertNext = false
                break
                
            case .rectangle(let rectangle):
                let v1 = rectangle.v1.multiply(by: transform)
                let v2 = rectangle.v2.multiply(by: transform)
                let v3 = rectangle.v3.multiply(by: transform)
                let v4 = rectangle.v4.multiply(by: transform)
                
                var winding = currentWinding
                if determinantFlip {
                    winding = winding.toggle()
                }
                
                let realColor = rectangle.color == 16 ? currentColor : rectangle.color
                let currentBuilder = geometryBuilders.builderForColor(realColor)
                if winding == partWinding {
                    currentBuilder.addTriangle(vertex1: v1, vertex2: v2, vertex3: v3)
                    currentBuilder.addTriangle(vertex1: v3, vertex2: v4, vertex3: v1)
                } else {
                    currentBuilder.addTriangle(vertex1: v3, vertex2: v2, vertex3: v1)
                    currentBuilder.addTriangle(vertex1: v1, vertex2: v4, vertex3: v3)
                }
                
                invertNext = false
                break
                
            case .optionalLine(let optionalLine):
                invertNext = false
                break
            }
        }
    }
}

fileprivate extension Bool {
    // XOR for bool
    static func ^ (left: Bool, right: Bool) -> Bool {
        return left != right
    }
}

fileprivate extension SCNVector3 {
    func multiply(by matrix: SCNMatrix4) -> SCNVector3 {
        let u = matrix.m11 * x + matrix.m21 * y + matrix.m31 * z + matrix.m41
        let v = matrix.m12 * x + matrix.m22 * y + matrix.m32 * z + matrix.m42
        let w = matrix.m13 * x + matrix.m23 * y + matrix.m33 * z + matrix.m43
        
        return SCNVector3(u, v, w)
    }
}
