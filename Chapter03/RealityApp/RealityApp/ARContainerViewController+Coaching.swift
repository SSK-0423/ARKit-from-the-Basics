//
//  ARContainerViewController+Coaching.swift
//  RealityApp
//
//  Created by ymtlab on 2022/05/25.
//

import Foundation
import ARKit

extension ARContainerViewController : ARCoachingOverlayViewDelegate {
    // コーチングオーバーレイビューのセットアップ
    func setupCoachingOverlay() {
        coachingOverlay.session = arView.session
        
        // ARViewの前面に追加する
        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        arView.addSubview(coachingOverlay)
        
        // ビュー全体をカバーする
        NSLayoutConstraint.activate([
            coachingOverlay.centerXAnchor.constraint(equalTo: arView.centerXAnchor),
            coachingOverlay.centerYAnchor.constraint(equalTo: arView.centerYAnchor),
            coachingOverlay.widthAnchor.constraint(equalTo: arView.widthAnchor),
            coachingOverlay.heightAnchor.constraint(equalTo: arView.heightAnchor)
        ])
        
        // セッションの状態で自動的に表示させる
        coachingOverlay.activatesAutomatically = true
        
        // 認識させるのは水平面
        coachingOverlay.goal = .horizontalPlane
    }
    
    // セッションリセットが必要な時の処理
    func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
        // コンテンツが配置済みなら削除する
        chair?.modelAnchor.removeFromParent()
        chair = nil
        
        // セッションをリセットする
        resetTracking()
    }
}
