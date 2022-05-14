//
//  ViewController+Coaching.swift
//  FirstSKAR
//
//  Created by ymtlab on 2022/05/14.
//

import Foundation
import ARKit

extension ViewController : ARCoachingOverlayViewDelegate {
    // コーチングオーバーレイビューのセットアップ
    /*
        1. セッションを設定する
        2. デリゲートを設定する
        3. ビューに追加する
        4. オートレイアウトの設定を行う
        5. セッション状態に応じて自動表示を行うかを設定する
        6. 認識させたい目的の設定
     */
    func setupCoachingOverlay(){
        coachingOverlay.session = sceneView.session
        coachingOverlay.delegate = self
        // シーンビューの前面に追加する
        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        sceneView.addSubview(coachingOverlay)
        
        // シーンビュー全体をカバーする
        NSLayoutConstraint.activate([
            coachingOverlay.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            coachingOverlay.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            coachingOverlay.widthAnchor.constraint(equalTo: view.widthAnchor),
            coachingOverlay.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
        
        // セッションの状態で自動的に表示させる
        coachingOverlay.activatesAutomatically = true
        
        // 認識させるのは水平面
        coachingOverlay.goal = .horizontalPlane
    }
    
    // コーチングオーバーレイビューが表示されるときに呼ばれる
    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        // アプリ側で用意しているコントロールを非表示にする
        sessionStatusLabel?.isHidden = true
    }
    
    // コーチングオーバーレイビューが非表示になる時に呼ばれる
    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        // アプリ側のコントロールを再表示する
        sessionStatusLabel?.isHidden = false
    }
    
    // セッションをリセットする必要があるときに呼ばれる
    func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
        removeChair()
        resetTracking()
    }
}
