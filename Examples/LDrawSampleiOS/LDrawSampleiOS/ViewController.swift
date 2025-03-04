//
//  ViewController.swift
//  LDrawSampleiOS
//
//  Created by iain on 04/03/2025.
//

import BrickKit
import UIKit
import SceneKit

class ViewController: UIViewController {
    var sceneView: SCNView!
    var currentNode: SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let partDir = ProcessInfo.processInfo.environment["PART_DIR"] else {
            fatalError("PART_DIR environment variable not set")
        }
        
        Task {
            try await BKColorManager.createSharedColorManager(from: partDir + "/LDConfig.ldr")
        }
        
        sceneView = SCNView()
        view.addSubview(sceneView)
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        sceneView.scene = SCNScene()
        sceneView.allowsCameraControl = true
        sceneView.showsStatistics = true
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zFar = 1000
        cameraNode.name = "Camera"
        sceneView.scene?.rootNode.addChildNode(cameraNode)
        
        cameraNode.position = SCNVector3(x: 0, y: 20, z: 60)
        cameraNode.look(at: SCNVector3Zero)
        
        let lightNode0 = SCNNode()
        lightNode0.light = SCNLight()
        lightNode0.light!.type = .omni
        lightNode0.position = SCNVector3(x: 0, y: 42, z: 7)
        sceneView.scene?.rootNode.addChildNode(lightNode0)
        
        let lightNode1 = SCNNode()
        lightNode1.light = SCNLight()
        lightNode1.light!.type = .ambient
        lightNode1.position = SCNVector3(20, -26, -27)
        sceneView.scene?.rootNode.addChildNode(lightNode1)
        
        Task {
            do {
                let options = BKFileLoaderOptions(basePath: .init(partDir), useHiRes: false)
                let part = try await BKFile.load(file: "28424p01.dat", options: options)
                let node = part.toNode(inverted: false)
                node.rotation = SCNVector4(1, 0, 0.2, .pi)
                
                sceneView.scene?.rootNode.addChildNode(node)
                
                node.mainColor = BKColorManager.shared.colorForID(19) ?? .systemBrown
                node.outlineColor = .black

//                let rotateAction = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: .pi, z: 0, duration: 5))
//                node.runAction(rotateAction)
                
                currentNode = node
            } catch {
                print("\(error)")
            }
        }
    }

    /*
    override var representedObject: Any? {
        didSet {
            guard let part = representedObject as? BKPart else {
                return
            }
            
            if currentNode != nil {
                currentNode?.removeFromParentNode()
            }
            
            let node = part.toNode(inverted: false)
            node.rotation = SCNVector4(x: 1, y: 0, z: 0.2, w: .pi)
            
            sceneView.scene?.rootNode.addChildNode(node)
            
            node.mainColor = BKColorManager.shared.colorForID(19) ?? .systemBrown
            node.outlineColor = .black
            
            let rotateAction = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: .pi, z: 0, duration: 5))
            node.runAction(rotateAction)
            
            currentNode = node
        }
    }
     */
}

