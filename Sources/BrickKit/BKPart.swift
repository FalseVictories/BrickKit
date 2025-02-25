//
//  File.swift
//  BrickKit
//
//  Created by iain on 17/02/2025.
//

import Foundation
import SceneKit

public enum WindingRule: Sendable {
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
    public func toNode(inverted: Bool,
                       transform: SCNMatrix4 = SCNMatrix4Identity,
                       determinant: Float = 0) -> SCNNode {
        let rootNode = SCNNode()
        rootNode.name = filename
        
//        var currentWinding: WindingRule = .CCW
        var partWinding: WindingRule = .CCW
        var currentWinding: WindingRule = inverted ? .CW : .CCW

        print("[\(filename)] Determinant: \(determinant)")
        if determinant < 0 {
            print("[\(filename)] Inverting because determinant is negative")
//            currentWinding = currentWinding.toggle()
        }
        
        var currentInversion = inverted
        var invertNext = false
        
        var currentIndices: [UInt16] = []
        var currentVertices: [SCNVector3] = []
        var buildingGeo: Bool = false
        
        lines.forEach {
            switch $0 {
            case .end:
                break
                
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
                
                let accumTransform = SCNMatrix4Mult(subpart.transform, transform)
                
                let node = part.toNode(inverted: currentInversion ^ invertNext,
                                       transform: subpart.transform,
                                       determinant: accumTransform.determinant).flattenedClone()
                node.name = part.filename
                node.transform = transform
                
                rootNode.addChildNode(node)

                invertNext = false

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
                
                break
                
            case .meta(let meta):
                switch meta {
                    
                case .invertNextInstruction:
                    invertNext = true
                    
                    print("[\(filename)] Inverting next: \(currentInversion)")
                    break
                    
                case .fileWinding(let newWinding):
                    print("[\(filename)] Changing winding: \(newWinding)")
                    currentWinding = newWinding
                    
                    if currentInversion {
                        currentWinding = currentWinding.toggle()
                    }
                    break
                    
                case .certified(let certified, let winding):
                    print("[\(filename)] Certified: \(certified), winding: \(winding)")
                    currentWinding = winding
                    partWinding = winding
                    
                    if currentInversion {
                        currentWinding = currentWinding.toggle()
                        print("[\(filename)] Inverting after certified: \(currentWinding)")
                    }
                    
                    if determinant < 0 {
                        print("[\(filename)] Inverting after certified because determinant is negative")
//                        currentWinding = currentWinding.toggle()
                    }

                    break
                    
                case .clip(let clip, let winding):
                    print("[\(filename)] Clip: \(clip), winding: \(winding)")
                    currentWinding = winding
                    
                    if currentInversion {
                        currentWinding = currentWinding.toggle()
                    }
                    break
                    
                case .ignore:
                    break
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
                
                var winding = currentWinding
                if determinant < 0 {
                    winding = winding.toggle()
                }
                if winding != partWinding {
//                if currentWinding == .CW {
                    currentIndices.append(vertexIndex + 2)
                    currentIndices.append(vertexIndex + 1)
                    currentIndices.append(vertexIndex)
                } else {
                    currentIndices.append(vertexIndex)
                    currentIndices.append(vertexIndex + 1)
                    currentIndices.append(vertexIndex + 2)
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
                
                var winding = currentWinding
                if determinant < 0 {
                    print("Inverting rect for determinant < 0")
                    winding = winding.toggle()
                }

                print("[\(filename)] Part: \(partWinding), \(winding)")
//                if currentWinding == .CW {
                if winding != partWinding {
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
                
                break
                
            case .optionalLine(_):
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
        geo.materials.first?.diffuse.contents = NSColor.systemGray
        
        node.transform = transform
        
        return node
    }
}

fileprivate extension Bool {
    static func ^ (left: Bool, right: Bool) -> Bool {
        return left != right
    }
}
