//
//  ViewController+Animation.swift
//  RealityAppTemplate
//
//  Created by 山本知仁 on 2022/05/26.
//

import Foundation
import ARKit
import RealityKit

extension ViewController {
    // 壁まで移動する
    func moveBallToWall(wall: ModelEntity) {
        guard let ball = ballModel, let plane = planeAnchor else {
            return
        }
        
        var transform = ball.transform
        
        // X座標だけを壁の位置に変更する
        transform.translation.x = wall.position.x
        
        playbackController = ball.move(to: transform,   // アニメーション後のtransform
                                       relativeTo: plane,   //
                                       duration: 3, // アニメーションの長さ
                                       timingFunction: .linear) // 変化
    }
}
