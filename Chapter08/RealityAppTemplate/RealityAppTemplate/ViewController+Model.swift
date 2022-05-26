//
//  ViewController+Model.swift
//  RealityAppTemplate
//
//  Created by 山本知仁 on 2022/05/26.
//

import Foundation
import ARKit
import RealityKit

extension ViewController {
    // 平面アンカーを作成する
    func addPlane() -> AnchorEntity {
        // 幅0.6 奥行き0.3以上の平面が必要
        let plane = AnchorEntity(plane: .horizontal,
                                 classification: .any,
                                 minimumBounds: [0.6,0.3])
        arView.scene.addAnchor(plane)
        return plane
    }
    
    // 壁を作成する
    func addWall(xPosition: Float, plane: AnchorEntity) -> ModelEntity {
        // ボックスを生成する
        let mesh = MeshResource.generateBox(size: [0.02,0.3,0.3])
        let material = SimpleMaterial(color: .white,
                                      roughness: 1.0,
                                      isMetallic: false)
        
        let model = ModelEntity(mesh: mesh, materials: [material])
        
        // アンカーエンティティに追加して、位置を設定する
        plane.addChild(model)
        model.position = [xPosition,0.15,0.0]
        
        // コリジョンコンポーネントを作成する
        model.generateCollisionShapes(recursive: false)
        
        return model
    }
    
    // ボールを作成する
    func addBall(plane: AnchorEntity) -> ModelEntity {
        // 球を生成する
        let mesh = MeshResource.generateSphere(radius: 0.03)
        let material = SimpleMaterial(color: .blue,
                                      roughness: 1.0,
                                      isMetallic: false)
        
        let model = ModelEntity(mesh: mesh, materials: [material])
        
        // アンカーエンティティに追加して、位置を調整する
        plane.addChild(model)
        model.position = [0.0,0.03,0.0]
        
        // コリジョンコンポーネントを作成する
        model.generateCollisionShapes(recursive: false)
        
        return model
    }
}
