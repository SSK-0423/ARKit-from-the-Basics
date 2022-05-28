//
//  ViewController+Model.swift
//  RealityAppTemplate
//
//  Created by 山本知仁 on 2022/05/27.
//

import Foundation
import ARKit
import RealityKit

extension ViewController {
    // 平面を作成する
    func addPlane() -> AnchorEntity {
        // アンカーエンティティを作成する
        let anchor = AnchorEntity(plane: .horizontal,classification: .any,minimumBounds:[0.3,0.3])
        arView.scene.addAnchor(anchor)
        
        // 平面メッシュを生成
        let mesh = MeshResource.generatePlane(width: 0.3, depth: 0.3)
        
        // 実際の平面をそのまま表示し、オクルージョンだけを行う
        let material = OcclusionMaterial(receivesDynamicLighting: true)
        
        // モデル作成
        let model = ModelEntity(mesh: mesh, materials: [material])
        
        // 物理情報を設定
        model.physicsBody = PhysicsBodyComponent(massProperties: .default,
                                                 material: .default,
                                                 mode: .static)
        
        // コリジョン設定
        model.generateCollisionShapes(recursive: false)
        
        // アンカーエンティティ追加
        anchor.addChild(model)
        
        return anchor
    }
    
    // ファイルからコンテンツを読み込んで配置する
    func addVirtualObject(name: String,
                          nameExtension: String,
                          position: SIMD3<Float>,
                          plane: AnchorEntity) -> VirtualObject {
        // ファイルを読み込んで配置する
        let obj = VirtualObject(modelAnchor: plane)
        obj.loadModel(name: name, nameExtension: nameExtension) { successed in
            guard successed else {
                return
            }
            
            // 物理情報を設定する
            let model = obj.modelEntity
            model?.physicsBody = PhysicsBodyComponent(massProperties: .default,
                                                      material: .default,
                                                      mode: .dynamic)
            
            // コリジョンを設定する
            model?.generateCollisionShapes(recursive: false)
            
            // 位置を調整する
            model?.position = position
        }
        
        return obj
    }
}
