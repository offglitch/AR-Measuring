//
//  ViewController.swift
//  AR Measuring
//
//  Created by Majid Alturki on 6/24/19.
//  Copyright © 2019 Majid Alturki. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    var center : CGPoint!
    
    let arrow = SCNScene(named: "art.scnassets/arrow.scn")!.rootNode
    
    // every time the renderer updates (about every 30 seconds) we create a new position and
    // assign it to an arrow
    // we want to average the last 10 positions
    
    var positions = [SCNVector3]()
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let hitTest = sceneView.hitTest(center, types: .featurePoint)
        let result = hitTest.last
        guard let transform = result?.worldTransform else {return}
        let thirdColumn = transform.columns.3
        let position = SCNVector3Make(thirdColumn.x, thirdColumn.y, thirdColumn.z)
        positions.append(position)
        let lastTenPositions = positions.suffix(10)
        arrow.position = getAveragePosition(from: lastTenPositions)
    }
    
    // This is helping function to get the average in SCNVector3 values
    func getAveragePosition(from positions : ArraySlice<SCNVector3>) -> SCNVector3 { // we're returning this because we want the average in SCNVector3
        var averageX : Float = 0
        var averageY : Float = 0
        var averageZ : Float = 0
        
        for position in positions {
            averageX += position.x
            averageY += position.y
            averageZ += position.z
        }
        let count = Float(positions.count)
        return SCNVector3Make(averageX / count , averageY / count, averageZ / count)
    }
    
    
    var isFirstPoint = true
    var points = [SCNNode]() // var to save all the points in nodes
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        
        let sphereGeometry = SCNSphere(radius: 0.005)
        let sphereNode = SCNNode(geometry: sphereGeometry)
        sphereNode.position = arrow.position //this should make sure there  object as to keep it in position
        sceneView.scene.rootNode.addChildNode(sphereNode)
        // when we add a child node to the sphere, we'll add it to points array
        points.append(sphereNode)
        
        if isFirstPoint {
            isFirstPoint = false
        } else {
            //calculate the distance
            let pointA = points[points.count - 2]
            guard let pointB = points.last else {return}
            
            let d = distance(float3(pointA.position), float3(pointB.position)) // casting to float3 from SCNVector3
            
            // add line
            let line = SCNGeometry.line(from: pointA.position, to: pointB.position)
            print(d.description)
            let lineNode = SCNNode(geometry: line)
            sceneView.scene.rootNode.addChildNode(lineNode)

            isFirstPoint = true
        }
        
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        center = view.center // This will keep the center of the object where it needs to be
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        center = view.center
        sceneView.scene.rootNode.addChildNode(arrow)
        sceneView.autoenablesDefaultLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
}


// a helper function that creates a line from one point to another
extension SCNGeometry {
    class func line(from vectorA : SCNVector3, to vectorB : SCNVector3) -> SCNGeometry {
        let indices : [Int32] = [0,1]
        let source = SCNGeometrySource(vertices: [vectorA, vectorB])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line) // the line we want to create
        return SCNGeometry(sources: [source], elements: [element])
    }
}
