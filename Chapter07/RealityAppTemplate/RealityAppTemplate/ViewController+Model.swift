//
//  ViewController+Model.swift
//  RealityAppTemplate
//
//  Created by ymtlab on 2022/05/25.
//

import Foundation
import ARKit
import RealityKit

extension ViewController{
    // ボックスをシーンに追加する
    func addBox(){
        // ボックスを作成する
        let mesh = MeshResource.generateBox(size: 0.05, cornerRadius: 0.01)
        
        var material = PhysicallyBasedMaterial()
        material.baseColor = PhysicallyBasedMaterial.BaseColor(tint: .white)
        material.roughness = PhysicallyBasedMaterial.Roughness(floatLiteral: 0.0)
        material.metallic = PhysicallyBasedMaterial.Metallic(floatLiteral: 1.0)
        
        let boxModel = ModelEntity(mesh: mesh, materials: [material])
        self.boxModel = boxModel
        
        // ボックスを平面アンカーエンティティに追加する
        planeAnchor?.addChild(boxModel)
        
        // ボックスの位置を微調整する
        boxModel.position = [0.0,0.01,0.0]
        boxModel.orientation = simd_quatf(angle: .pi, axis: [0.0,1.0,0.0])
    }
    
    // ポストを追加する
    func addPost(){
        // コンテンツを読み込む
        let obj = VirtualObject(modelAnchor: planeAnchor!)
        postObject = obj
        
        obj.loadModel(name: "Post", nameExtension: "usdz") {[weak self] isOK in
            // 読み込みに成功したか
            guard isOK else {
                return
            }
            
            // 位置と大きさを微調整する
            let model = self?.postObject?.modelEntity
            model?.position = [0.05,0.0,0.1]
            model?.setScale([0.7,0.7,0.7], relativeTo: model)
        }
    }
}
