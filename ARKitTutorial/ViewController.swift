//
//  ViewController.swift
//  ARKitTutorial
//
//  Created by Nicoleta Pop on 5/10/19.
//  Copyright © 2019 Nicoleta Pop. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Show feature points when a session is run
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Enable default lighting
        sceneView.autoenablesDefaultLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Set plane detection type to current configuration
        configuration.planeDetection = [.horizontal, .vertical]

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // To detect one or more touches in current view/window
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let touch = touches.first {
            
            let touchLocation = touch.location(in: sceneView)
            
            let results = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
            
            if let hitResult = results.first {
                
                // Create a new scene
                let diceScene = SCNScene(named: "art.scnassets/crsppdr.scn")!
                
                if let diceNode = diceScene.rootNode.childNode(withName: "Sphere", recursively: true) {
                    
                    diceNode.position = SCNVector3(
                        x: hitResult.worldTransform.columns.3.x,
                        //according to boundingSphere of 3D model, we have to calculate y position such that the spider will realistically be placed on a surface
                        y: hitResult.worldTransform.columns.3.y + /*diceNode.boundingSphere.radius/400*/diceNode.boundingBox.max.y/400,
                        z: hitResult.worldTransform.columns.3.z
                    )
                    
                    if (hitResult.anchor as? ARPlaneAnchor)?.alignment == .horizontal {
                        print("horizontal transform")
                        //no need to
                    } else if (hitResult.anchor as? ARPlaneAnchor)?.alignment == .vertical {
                        print("vertical transform")
                        //rotate around x-axis to realistically place Spider onto the vertical plane
                        
                        // using euler angles property
                        //diceNode.eulerAngles.x = Float.pi/2
                        
                        // using rotation property
                        //diceNode.rotation = SCNVector4(1, 0, 0, Float.pi/2)
                        
                        // using orientation property with OpenGL library - BEST solution
                        let orientation = diceNode.orientation
                        var glQuaternion = GLKQuaternionMake(orientation.x, orientation.y, orientation.z, orientation.w)
                        
                        let multiplier = GLKQuaternionMakeWithAngleAndAxis(Float.pi/2, 1, 0, 0)
                        glQuaternion = GLKQuaternionMultiply(glQuaternion, multiplier)
                        
                        diceNode.orientation = SCNQuaternion(glQuaternion.x, glQuaternion.y, glQuaternion.z, glQuaternion.w)
                    }
                    
                    sceneView.scene.rootNode.addChildNode(diceNode)
                    
                }
                
            }
            
        }
    }

    // Add a grid placeholder when a plane is detected
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        if anchor is ARPlaneAnchor {
            let planeAnchor = anchor as! ARPlaneAnchor
            
            if planeAnchor.alignment == .horizontal {
                print("horizontal plane detected")
            } else if planeAnchor.alignment == .vertical {
                print("vertical plane detected")
            }
                
            let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
                
            let gridMaterial = SCNMaterial()
            gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/grid.png")
            plane.materials = [gridMaterial]
                
            let planeNode = SCNNode()
                
            planeNode.geometry = plane
            //the grid will be placed in the center of the detected plane
            planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
            //rotate grid around x axis with -90 degrees angle (-pi/2 in radians)
            planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
                
            node.addChildNode(planeNode)
            
        } else {
            return
        }
    }

}
