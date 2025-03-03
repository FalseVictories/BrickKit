//
//  BKPartNode.swift
//  BrickKit
//
//  Created by iain on 27/02/2025.
//

import AppKit
import SceneKit

@MainActor
public class BKPartNode: SCNNode {
    public var mainColor: NSColor = .gray {
        didSet {
            if let triangleNode = colorTriangleNodes[16] {
                triangleNode.geometry?.firstMaterial?.diffuse.contents = mainColor
                triangleNode.childNodes.forEach {
                    $0.geometry?.firstMaterial?.diffuse.contents = mainColor
                }
            }
        }
    }
    
    public var outlineColor: NSColor = .black {
        didSet {
            if let lineNode = colorLineNodes[24] {
                lineNode.geometry?.firstMaterial?.diffuse.contents = outlineColor
                lineNode.childNodes.forEach {
                    $0.geometry?.firstMaterial?.diffuse.contents = outlineColor
                }
            }
        }
    }
    
    var colorTriangleNodes: [BKColorCode: SCNNode] = [:]
    var colorLineNodes: [BKColorCode: SCNNode] = [:]
    
    init(colorBuilders: GeometryBuilderCollection) {
        super.init()

        colorBuilders.builders.forEach {
            let color = $0.key
            let geometryBuilder = $0.value
            
            let c = BKColorManager.shared.colorForID(color)
            
            let (trianglesVertices, triangleIndicies) = geometryBuilder.splitToMaxTriangles()
            
            var triangleRootNode: SCNNode?
            
            let tCount = triangleIndicies.count
            if tCount > 1 {
                triangleRootNode = SCNNode()
                triangleRootNode?.name = "Triangles"
                
                for i in 0 ..< triangleIndicies.count {
                    let tnode = createNode(verticies: trianglesVertices[i], indicies: triangleIndicies[i], primitiveType: .triangles)
                    tnode.name = "Triangle \(i) Color \(color)"
                    tnode.geometry?.firstMaterial?.diffuse.contents = c
                    triangleRootNode?.addChildNode(tnode)
                }
            } else if tCount == 1 {
                triangleRootNode = createNode(verticies: trianglesVertices[0], indicies: triangleIndicies[0], primitiveType: .triangles)
                triangleRootNode?.geometry?.firstMaterial?.diffuse.contents = c
                triangleRootNode?.name = "Triangles \(color)"
            }
            
            if let triangleRootNode {
                addChildNode(triangleRootNode)
                colorTriangleNodes[color] = triangleRootNode
            }
            
            var lineRootNode: SCNNode?
            
            let (lineVertices, lineIndicies) = geometryBuilder.splitToMaxLines()
            
            let lCount = lineIndicies.count
            if lCount > 1 {
                lineRootNode = SCNNode()
                
                for i in 0 ..< lineIndicies.count {
                    let tnode = createNode(verticies: lineVertices[i], indicies: lineIndicies[i], primitiveType: .line)
                    tnode.name = "Lines \(i) Color \(color)"
                    lineRootNode?.addChildNode(tnode)
                }
            } else if lCount == 1 {
                lineRootNode = createNode(verticies: lineVertices[0],
                                          indicies: lineIndicies[0], primitiveType: .line)
                lineRootNode?.name = "Lines Color \(color)"
            }

            if let lineRootNode {
                addChildNode(lineRootNode)
                colorLineNodes[color] = lineRootNode
            }
        }
    }
        
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension BKPartNode {
    func createNode(verticies: [SCNVector3],
                    indicies: [UInt16],
                    primitiveType: SCNGeometryPrimitiveType ) -> SCNNode {
        let src = SCNGeometrySource(vertices: verticies)
        let element = SCNGeometryElement(indices: indicies,
                                         primitiveType: primitiveType)
        let geo = SCNGeometry(sources: [src],
                                      elements: [element])
        return SCNNode(geometry: geo)
    }
}
