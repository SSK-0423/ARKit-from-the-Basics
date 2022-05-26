//
//  ViewController+Collision.swift
//  RealityAppTemplate
//
//  Created by 山本知仁 on 2022/05/26.
//

import Foundation
import ARKit
import RealityKit

extension ViewController {
    //　コリジョンイベント受け取り時の処理
    func onCollisionBegan(_ event: CollisionEvents.Began){
        guard event.entityA == ballModel else {
            return
        }
        
        if event.entityB == leftWallModel {
            // 左側の壁に衝突した
            if let wall = rightWallModel {
                moveBallToWall(wall: wall)
            }
        } else if event.entityB == rightWallModel {
            // 右側の壁に衝突した
            if let wall = leftWallModel {
                moveBallToWall(wall: wall)
            }
        }
    }
}
