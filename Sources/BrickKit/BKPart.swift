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

class GeometryBuilder {
    var lineVerticies: [SCNVector3] = []
    var lineIndices: [UInt16] = []
    var lineCount = 0
    
    var triangleVerticies: [SCNVector3] = []
    var triangleIndices: [UInt16] = []
    var triangleCount = 0
    
    func addLine(from: SCNVector3, to: SCNVector3) {
        lineVerticies.append(contentsOf: [from, to])
        lineIndices.append(contentsOf: [UInt16(lineCount), UInt16(lineCount + 1)])
        lineCount += 2
    }
    
    // Does not consider winding rules, caller must order the vertices accordingly
    func addTriangle(vertex1: SCNVector3, vertex2: SCNVector3, vertex3: SCNVector3) {
        triangleVerticies.append(contentsOf: [vertex1, vertex2, vertex3])
        triangleIndices.append(contentsOf: [UInt16(triangleCount),
                                            UInt16(triangleCount + 1),
                                            UInt16(triangleCount + 2)])
        triangleCount += 3
    }
}

public struct BKPart: Sendable {
    public let colour: Int32
    let filename: String
    let lines: [BKFileLine]
    
    @MainActor
    public func toNode(inverted: Bool = false,
                       transform: SCNMatrix4 = SCNMatrix4Identity) -> BKPartNode {
        var geometryBuilder = GeometryBuilder()
        buildGeometry(inverted: inverted,
                      transform: transform,
                      geometryBuilder: geometryBuilder)
                
        let triangleSrc = SCNGeometrySource(vertices: geometryBuilder.triangleVerticies)
        let triangleElement = SCNGeometryElement(indices: geometryBuilder.triangleIndices,
                                                 primitiveType: .triangles)
        let triangleGeo = SCNGeometry(sources: [triangleSrc],
                              elements: [triangleElement])
        
        let lineSrc = SCNGeometrySource(vertices: geometryBuilder.lineVerticies)
        let lineElement = SCNGeometryElement(indices: geometryBuilder.lineIndices,
                                             primitiveType: .line)
        let lineGeo = SCNGeometry(sources: [lineSrc],
                                  elements: [lineElement])
        
        let node = BKPartNode(triangleGeometry: triangleGeo, lineGeometry: lineGeo)
        node.name = filename
        
        return node
    }
    
    func buildGeometry(inverted: Bool = false,
                       transform: SCNMatrix4 = SCNMatrix4Identity,
                       geometryBuilder: GeometryBuilder) {
        var partWinding = WindingRule.CCW
        var currentWinding = WindingRule.CCW
        var invertNext = false
        let determinantFlip = transform.determinant < 0
        
        for line in lines {
            switch line {
            case .end:
                return

            case .subpart(let subpart, let part):
                part.buildGeometry(inverted: inverted ^ invertNext,
                                   transform: SCNMatrix4Mult(subpart.transform, transform),
                                   geometryBuilder: geometryBuilder)
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
                
                geometryBuilder.addLine(from: v1, to: v2)
                
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

                if winding == partWinding {
                    geometryBuilder.addTriangle(vertex1: v1, vertex2: v2, vertex3: v3)
                } else {
                    geometryBuilder.addTriangle(vertex1: v3, vertex2: v2, vertex3: v1)
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
                
                if winding == partWinding {
                    geometryBuilder.addTriangle(vertex1: v1, vertex2: v2, vertex3: v3)
                    geometryBuilder.addTriangle(vertex1: v3, vertex2: v4, vertex3: v1)
                } else {
                    geometryBuilder.addTriangle(vertex1: v3, vertex2: v2, vertex3: v1)
                    geometryBuilder.addTriangle(vertex1: v1, vertex2: v4, vertex3: v3)
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
