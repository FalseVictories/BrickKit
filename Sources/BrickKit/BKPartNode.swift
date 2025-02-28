//
//  BKPartNode.swift
//  BrickKit
//
//  Created by iain on 27/02/2025.
//

import AppKit
import SceneKit


public class BKPartNode: SCNNode {
    public var mainColor: NSColor = .gray {
        didSet {
            triangleNode.geometry?.firstMaterial?.diffuse.contents = mainColor
        }
    }
    
    public var outlineColor: NSColor = .black {
        didSet {
            lineNode.geometry?.firstMaterial?.diffuse.contents = outlineColor
        }
    }
    
    let lineNode: SCNNode
    let triangleNode: SCNNode
    
    init(triangleGeometry: SCNGeometry,
         lineGeometry: SCNGeometry) {
        triangleNode = SCNNode(geometry: triangleGeometry)
        lineNode = SCNNode(geometry: lineGeometry)
        
        super.init()
        
        triangleNode.name = "Triangles"
        lineNode.name = "Lines"
        
        addChildNode(triangleNode)
        addChildNode(lineNode)
        
        triangleNode.geometry?.firstMaterial?.diffuse.contents = mainColor
        lineNode.geometry?.firstMaterial?.diffuse.contents = outlineColor
    }
    
    init(triangleNode: SCNNode,
         lineNode: SCNNode) {
        self.lineNode = lineNode
        self.triangleNode = triangleNode
        
        super.init()
        
        triangleNode.name = "Triangles"
        lineNode.name = "Lines"
        
        addChildNode(triangleNode)
        addChildNode(lineNode)
        
        triangleNode.geometry?.firstMaterial?.diffuse.contents = mainColor
        triangleNode.childNodes.forEach { $0.geometry?.firstMaterial?.diffuse.contents = mainColor }
        
        lineNode.geometry?.firstMaterial?.diffuse.contents = outlineColor
        lineNode.childNodes.forEach { $0.geometry?.firstMaterial?.diffuse.contents = outlineColor }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
