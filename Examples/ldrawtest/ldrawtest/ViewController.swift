//
//  ViewController.swift
//  ldrawtest
//
//  Created by iain on 16/02/2025.
//

import Cocoa
import SceneKit
import BrickKit

class ViewController: NSViewController {
    var sceneView: SCNView!
    var partTableViewController: PartTableViewController!
    
    var currentNode: SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let partDir = ProcessInfo.processInfo.environment["PART_DIR"] else {
            fatalError("PART_DIR environment variable not set")
        }

        Task {
            try await BKColorManager.createSharedColorManager(from: partDir + "/LDConfig.ldr")
        }

        partTableViewController = PartTableViewController(withPartsFolder: partDir)
        addChild(partTableViewController)
        
        view.addSubview(partTableViewController.view)
        partTableViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        partTableViewController.partSelectionHandler = { [weak self] part in
            Task {
                do {
                    let options = BKFileLoaderOptions(basePath: .init(partDir), useHiRes: false)
                    self?.representedObject = try await BKFile.load(file: part, options: options)
                } catch {
                    print("\(error)")
                }
            }
        }
        
        // Do any additional setup after loading the view.
        sceneView = SCNView()
        view.addSubview(sceneView)
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            partTableViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            partTableViewController.view.widthAnchor.constraint(equalToConstant: 150),
            partTableViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            partTableViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.leadingAnchor.constraint(equalTo: partTableViewController.view.trailingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
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
        
        // 3023 1x2 plate
        // 3022 2x2 plate
        // 3024 1x2 plate
        // 4073 1x1 round plate
        // 2654 - boat stud
        // 61069 side thruster
        // 26021 - rollercoaster base
        // 2549 - bridge
        // 61975 - coiled whip
        // 90826 - broom
        
        // NOCERTIFY: 2867, 2865
        // 55816 
        
    }
    
    override var representedObject: Any? {
        didSet {
            guard let part = representedObject as? BKPart else {
                return
            }
            
            if currentNode != nil {
                currentNode?.removeFromParentNode()
            }
            
            let node = part.toNode(inverted: false)
            
            view.window?.title = node.name ?? ""
            
            node.rotation = SCNVector4(x: 1, y: 0, z: 0.2, w: .pi)
            
            sceneView.scene?.rootNode.addChildNode(node)
            
            node.mainColor = BKColorManager.shared.colorForID(19) ?? .systemBrown
            node.outlineColor = .black
            
            let rotateAction = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: .pi, z: 0, duration: 5))
            node.runAction(rotateAction)
            
            currentNode = node
        }
    }
}
