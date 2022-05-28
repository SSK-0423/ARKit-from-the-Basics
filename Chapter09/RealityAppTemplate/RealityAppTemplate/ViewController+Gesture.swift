//
//  ViewController+Gesture.swift
//  RealityAppTemplate
//
//  Created by 山本知仁 on 2022/05/27.
//

import Foundation
import ARKit
import RealityKit

extension ViewController {
    // タップジェスチャーの処理
    @objc func handleTap(_ tap: UIGestureRecognizer) {
        // ジェスチャー完了時のみ処理する
        guard tap.state == .ended else {
            return
        }
        
        // タップされたモデルエンティティを調べる
        let location = tap.location(in: arView)
        let results = arView.hitTest(location)
        
        let tappedObj: [VirtualObject] = virtualOjbects.filter { obj in
            results.contains { $0.entity == obj.modelEntity}
        }
        
        tappedObj.forEach() { tapVirtualObject($0) }
    }
    
    // 仮想コンテンツのタップ処理
    func tapVirtualObject(_ obj: VirtualObject) {
        // 加える衝撃の大きさ
        var impulse: SIMD3<Float> = [0.0,0.0,-0.5]
        
        // カメラの向きになるように回転する
        // カメラの向きを取得 クォータニオン
        let cameraOrientation = arView.cameraTransform.rotation
        impulse = cameraOrientation.act(impulse)
        
        // モデルに衝撃を加える 単位ニュートン秒(N・s)
        obj.modelEntity?.applyLinearImpulse(impulse,
                                            relativeTo: nil)
        
        // 衝撃による回転の大きさ
        var torque: SIMD3<Float> = [-0.2,0.0,0.0]
        
        // カメラの向きになるように回転する 単位kg・m^2/s
        torque = cameraOrientation.act(torque)
        
        // 回転する衝撃を加える
        obj.modelEntity?.applyAngularImpulse(torque, relativeTo: nil)
    }
    
    // 長押しジェスチャーの処理
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            // 押されたモデルエンティティを調べる
            let location = gesture.location(in: arView)
            let results = arView.hitTest(location)
            
            // 押されたオブジェクトを取得する
            pressObject = virtualOjbects.first { obj in
                results.contains { $0.entity == obj.modelEntity }
            }
        } else if gesture.state == .ended {
            // ジェスチャー完了なのでクリアする
            pressObject = nil
        }
    }
    
    // フレーム更新イベントの処理、長押しされている仮想コンテンツの処理
    func onUpdateFrame(_ events: SceneEvents.Update) {
        // 加える衝撃の大きさ
        var impulse: SIMD3<Float> = [0.0,0.0,-0.5]
        
        // カメラの向きになるように回転する
        let cameraOrientation = arView.cameraTransform.rotation
        impulse = cameraOrientation.act(impulse)
        
        // モデルに力を加える
        pressObject?.modelEntity?.addForce(impulse, relativeTo: nil)
        
        // 衝撃による回転の大きさ
        var torque: SIMD3<Float> = [-0.2,0.0,0.0]
        
        // カメラの向きになるように回転する
        torque = cameraOrientation.act(torque)
        pressObject?.modelEntity?.addTorque(torque, relativeTo: nil)
    }
}
