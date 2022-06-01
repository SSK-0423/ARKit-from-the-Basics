//
//  BodyTrackingObject.swift
//  RealityAppTemplate
//
//  Created by 山本知仁 on 2022/05/30.
//

import Foundation
import ARKit
import RealityKit
import Combine

class BodyTrackingObject {
    let anchor = AnchorEntity()
    var trackedEntity: BodyTrackedEntity?
    var cancellable: AnyCancellable?
    var leftTrigger: TriggerVolume?
    var rightTrigger: TriggerVolume?
    
    init(){
        
    }
    
    // 
    func load(name: String, nameExtension: String) {
        // 指定されたファイルへのURLを取得する
        guard let url = Bundle.main.url(forResource: name,
                                        withExtension: nameExtension) else {
            return
        }
        
        // ファイルから非同期で読み込む
        cancellable = Entity.loadBodyTrackedAsync(contentsOf: url, withName: nil)
            .sink(receiveCompletion: { loadCompletion in
                // 完了処理
                if case let .failure(error) = loadCompletion {
                    // 読み込みエラー発生
                    print(error.localizedDescription)
                }
            }, receiveValue: {[weak self] entity in
                // モデル取得処理
                self?.trackedEntity = entity
                
                // スケールを初期化
                entity.scale = [1.0,1.0,1.0]
            })
    }
    
    // ARBodyAnchorの反映
    func update(with bodyAnchor: ARBodyAnchor) {
        // 位置と向きを合わせる
        let transform = Transform(matrix: bodyAnchor.transform)
        anchor.position = transform.translation
        anchor.orientation = transform.rotation
        
        // ボディモデルの読み込みが完了しているが、シーンに追加されていないかの確認
        if let entity = trackedEntity, trackedEntity?.parent == nil {
            // アンカーエンティティの子エンティティとして追加
            anchor.addChild(entity)
            // トリガーボリュームを作成する
            addTriggerVolume()
        }
        
        updateTriggerVolume(with: bodyAnchor)
    }
    
    // トリガーボリュームの作成
    func addTriggerVolume() {
        // 半径5cm程度の球体のトリガーボリュームを作成する
        // 左手
        let leftShape = ShapeResource.generateSphere(radius: 0.05)
        let left = TriggerVolume(shape: leftShape)
        leftTrigger = left
        anchor.addChild(left)
        
        // 右手
        let rightShape = ShapeResource.generateSphere(radius: 0.05)
        let right = TriggerVolume(shape: rightShape)
        rightTrigger = right
        anchor.addChild(right)
    }
    
    // トリガーボリュームの位置調整
    func updateTriggerVolume(with bodyAnchor: ARBodyAnchor) {
        // 左手
        if let leftTransform = bodyAnchor.skeleton.modelTransform(for: .leftHand) {
            leftTrigger?.position = simd_make_float3(leftTransform.columns.3)
        }
        
        // 右手
        if let rightTransform = bodyAnchor.skeleton.modelTransform(for: .rightHand) {
            rightTrigger?.position = simd_make_float3(rightTransform.columns.3)
        }
    }
}
