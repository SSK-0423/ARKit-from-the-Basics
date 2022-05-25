//
//  ARContainerViewController.swift
//  RealityApp
//
//  Created by ymtlab on 2022/05/24.
//

import UIKit
import ARKit
import RealityKit

class ARContainerViewController: UIViewController, ARSessionDelegate {
    var arView: ARView!
    var chair: VirtualObject?
    var coachingOverlay = ARCoachingOverlayView()
    
    override func loadView(){
        self.view = UIView(frame: .zero)
        
        // RealityKitのARViewを作成する
        arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        
        arView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(arView)
        
        // 左右上下にフィットさせる
        NSLayoutConstraint.activate([
            arView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            arView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            arView.widthAnchor.constraint(equalTo: view.widthAnchor),
            arView.topAnchor.constraint(equalTo: view.topAnchor),
            arView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // デリゲートを設定
        arView.session.delegate = self
        // タップジェスチャーを設定する
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        arView.addGestureRecognizer(tap)
        
        // コーチングオーバーレイビューをセットアップする
        setupCoachingOverlay()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        resetTracking()
        
        // アンカーを作成する
        let isSupported = ARPlaneAnchor.isClassificationSupported
        let modelAnchor = AnchorEntity(plane: .horizontal,
                                       classification: isSupported ? .floor : .any,
                                       minimumBounds: [0.5,0.5])
        // コンテンツを読み込む
        chair = VirtualObject(modelAnchor: modelAnchor)
        chair?.loadChair(){[weak self] isSuccessed in
            if isSuccessed {
                // 読み込みに成功したのでシーンに追加する
                self?.arView.scene.addAnchor(modelAnchor)
            }
        }
    }
    
    // ARセッション中断時の処理
    func sessionWasInterrupted(_ session: ARSession) {
        // 配置済みのコンテンツを非表示にする
        if let chair = self.chair {
            chair.modelAnchor.isEnabled = false
        }
    }
    
    // ARセッション再開時の処理
    func sessionInterruptionEnded(_ session: ARSession) {
    }
    
    // セッションエラー発生時の処理
    func session(_ session: ARSession, didFailWithError error: Error) {
        // ARKitから通知されたエラー以外なら処理しない
        guard error is ARError else {
            return
        }
        
        // エラーメッセージを作る
        var message = (error as NSError).localizedDescription
        if let reason = (error as NSError).localizedFailureReason {
            message += "\n\(reason)"
        }
        if let suggestion = (error as NSError).localizedRecoverySuggestion {
            message += "\n\(suggestion)"
        }
        
        // エラーメッセージを表示する
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "ARSession Failed",
                                          message: message,
                                          preferredStyle: .alert)
            let reset = UIAlertAction(title: "Reset Tracking",
                                      style: .default) { _ in
                self.resetTracking()
            }
            alert.addAction(reset)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // カメラのトラッキング精度変更時の処理
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .normal:
            // 配置済みコンテンツを再表示する
            chair?.modelAnchor.isEnabled = true
            break
        default:
            break
        }
    }
    
    // リローカライズ実行判定
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        // 配置済みのコンテンツがあるときはリローカライズ処理を行う
        return (chair != nil)
    }
    
    // タップされた時の処理
    @objc func didTap(_ gesture: UITapGestureRecognizer){
        // ジェスチャー完了チェック
        guard gesture.state == .ended else {
            return
        }
        
        // タップされた座標を取得
        let location = gesture.location(in: arView)
        
        // レイキャストを実行する
        let results = arView.raycast(from: location,
                                     allowing: .estimatedPlane,
                                     alignment: .horizontal)
        
        if results.count > 0 {
            // 検出結果を取得できた
            // 配置済みのコンテンツを削除する
            if let chair = self.chair {
                arView.scene.removeAnchor(chair.modelAnchor)
                self.chair = nil
            }
            
            // レイキャストの実行結果を使って、アンカーを作成する
            // レイキャストで得た座標上にアンカーエンティティを作成
            let anchor = AnchorEntity(raycastResult: results[0])
            // コンテンツを読み込む
            chair = VirtualObject(modelAnchor: anchor)
            chair?.loadChair(){[weak self] isSuccessed in
                if isSuccessed {
                    // 読み込みに成功したのでシーンに追加する
                    self?.arView.scene.addAnchor(anchor)
                }
            }
        }
    }
    
    // ARセッションをリセットする
    func resetTracking(){
        let config = ARWorldTrackingConfiguration()
        
        // 水平面を検出する
        config.planeDetection = [.horizontal]
        // セッションを開始する
        arView.session.run(config, options: [.removeExistingAnchors, .resetTracking])
    }
}
