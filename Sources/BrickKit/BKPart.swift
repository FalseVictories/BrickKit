//
//  File.swift
//  BrickKit
//
//  Created by iain on 17/02/2025.
//

import Foundation
import SceneKit

public enum WindingRule {
    case CCW
    case CW
    
    func toggle() -> Self {
        self == .CCW ? .CW : .CCW
    }
}

public struct BKPart: Sendable {
    @MainActor public static var geoCount: Int = 0
    
    public let colour: Int32
    let filename: String
    let lines: [BKFileLine]
    
    @MainActor
    public func toNode(withWindingRule winding: WindingRule,
                       transform: SCNMatrix4 = SCNMatrix4Identity) -> SCNNode {
        let rootNode = SCNNode()
        rootNode.name = filename
        
        var currentWinding = winding
        var temporaryWinding = false
        
        if transform.determinant < 0 {
            currentWinding = currentWinding.toggle()
        }
        
        var currentIndices: [UInt16] = []
        var currentVertices: [SCNVector3] = []
        var buildingGeo: Bool = false
        
        lines.forEach {
            switch $0 {
            case .subpart(let subpart, let part):
                if buildingGeo {
                    let node = processGeometry(verticies: currentVertices,
                                               indices: currentIndices,
                                               transform: transform)
                    rootNode.addChildNode(node)
                    buildingGeo = false
                    currentVertices = []
                    currentIndices = []
                }
                
                let node = part.toNode(withWindingRule: currentWinding,
                                       transform: subpart.transform).flattenedClone()
                node.name = part.filename
                node.transform = transform
                
                rootNode.addChildNode(node)
                
                if temporaryWinding {
                    currentWinding = currentWinding.toggle()
                    temporaryWinding = false
                }

                break
                
            case .line(let line):
                let src = SCNGeometrySource(vertices: [line.v1, line.v2])
                let indices: [UInt16] = [0, 1]
                let element = SCNGeometryElement(indices: indices,
                                                 primitiveType: .line)
                let geo = SCNGeometry(sources: [src], elements: [element])
                let node = SCNNode(geometry: geo)
                node.geometry?.materials.first?.diffuse.contents = NSColor.black
                node.transform = transform
                rootNode.addChildNode(node)
                
                if temporaryWinding {
                    currentWinding = currentWinding.toggle()
                    temporaryWinding = false
                }

                break
                
            case .meta(let meta):
                if meta == .invertNextInstruction {
                    currentWinding = currentWinding.toggle()
                    temporaryWinding = true
                    
                    print("Inverting next: \(currentWinding)")
                }
                break
                
            case .triangle(let triangle):
                if !buildingGeo {
                    buildingGeo = true
                }
                
                let vertexIndex = UInt16(currentVertices.count)
                
                currentVertices.append(triangle.v1)
                currentVertices.append(triangle.v2)
                currentVertices.append(triangle.v3)
                
                if currentWinding == .CW {
                    currentIndices.append(vertexIndex + 2)
                    currentIndices.append(vertexIndex + 1)
                    currentIndices.append(vertexIndex)
                } else {
                    currentIndices.append(vertexIndex)
                    currentIndices.append(vertexIndex + 1)
                    currentIndices.append(vertexIndex + 2)
                }

                if temporaryWinding {
                    currentWinding = currentWinding.toggle()
                    temporaryWinding = false
                }
                break
                
            case .rectangle(let rectangle):
                if !buildingGeo {
                    buildingGeo = true
                }
                
                let vertexIndex = UInt16(currentVertices.count)
                
                currentVertices.append(rectangle.v1)
                currentVertices.append(rectangle.v2)
                currentVertices.append(rectangle.v3)
                currentVertices.append(rectangle.v4)
                
                if currentWinding == .CW {
                    currentIndices.append(vertexIndex + 2)
                    currentIndices.append(vertexIndex + 1)
                    currentIndices.append(vertexIndex)
                    
                    currentIndices.append(vertexIndex + 3)
                    currentIndices.append(vertexIndex + 2)
                    currentIndices.append(vertexIndex)
                } else {
                    currentIndices.append(vertexIndex)
                    currentIndices.append(vertexIndex + 1)
                    currentIndices.append(vertexIndex + 2)
                    
                    currentIndices.append(vertexIndex)
                    currentIndices.append(vertexIndex + 2)
                    currentIndices.append(vertexIndex + 3)
                }

                if temporaryWinding {
                    currentWinding = currentWinding.toggle()
                    temporaryWinding = false
                }

                break
                
            case .optionalLine(_):
                if temporaryWinding {
                    currentWinding = currentWinding.toggle()
                    temporaryWinding = false
                }

                break
            }
        }
        
        if buildingGeo {
            let node = processGeometry(verticies: currentVertices,
                                       indices: currentIndices,
                                       transform: transform)
            rootNode.addChildNode(node)
            buildingGeo = false
            currentVertices = []
            currentIndices = []
        }

        return rootNode
    }
}

private extension BKPart {
    @MainActor
    func processGeometry(verticies: [SCNVector3],
                         indices: [UInt16],
                         transform: SCNMatrix4) -> SCNNode {
        let src = SCNGeometrySource(vertices: verticies)
        let element = SCNGeometryElement(indices: indices,
                                         primitiveType: .triangles)
        let geo = SCNGeometry(sources: [src], elements: [element])
        
        BKPart.geoCount += 1
        
        let node = SCNNode(geometry: geo)
        
        node.geometry?.firstMaterial?.diffuse.contents = NSColor.random()
        node.transform = transform
        
        return node
    }
}

fileprivate extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}

fileprivate extension NSColor {
    static func random() -> NSColor {
        return NSColor(
           red:   .random(),
           green: .random(),
           blue:  .random(),
           alpha: 1.0
        )
    }
}
