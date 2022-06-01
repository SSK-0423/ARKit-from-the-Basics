//
//  ViewController.swift
//  RealityAppTemplate
//
//  Created by ymtlab on 2022/05/25.
//

import UIKit
import RealityKit
import ARKit
import CoreImage
import Combine

class ViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet var arView: ARView!
    var coachingOverlay = ARCoachingOverlayView()
    let bodyTrackingObject = BodyTrackingObject()
    var ciContext: CIContext?
    var isApplyEffect = false
    var collisionBegan: Cancellable?
    
    // UIViewControllerのプロパティ
    override func loadView() {
        self.view = UIView(frame:.zero)
        // RealityKitのARViewを作成する
        arView = ARView(frame: .zero,
                        cameraMode: .ar,
                        automaticallyConfigureSession: false)
        arView.translatesAutoresizingMaskIntoConstraints = false
        // ARViewをviewのサブビューにする
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
        
        // コーチングオーバーレイビューをセットアップする
        setupCoachingOverlay()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        resetTracking()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // ポストプロセスエフェクト用のコールバック関数を設定する
        // 最初のレンダリング前に一回だけ呼ばれる
        arView.renderCallbacks.prepareWithDevice = preparePostProcessing
        // 毎フレーム呼ばれる
        arView.renderCallbacks.postProcess = postProcesing
    }
    
    // ARセッションをリセットする
    func resetTracking() {
        // モーションキャプチャに対応しているデバイスかを確認する
        guard ARBodyTrackingConfiguration.isSupported else {
            // 非対応デバイス
            fatalError("This device doesn't support AR Body Trackinig.")
        }
        
        // コリジョンを有効化する
        arView.environment.sceneUnderstanding.options = [.collision]
        
        let config = ARBodyTrackingConfiguration()
        
        // セッションを開始する
        arView.session.run(config, options: [.removeExistingAnchors,.resetTracking])
        
        // ボディモデルをシーンに追加する
        arView.scene.addAnchor(bodyTrackingObject.anchor)
        // モデル読み込み
        bodyTrackingObject.load(name: "robot", nameExtension: "usdz")
        
        // コリジョンイベントを受け取る
        collisionBegan = arView.scene.subscribe(to: CollisionEvents.Began.self,
                                                onCollisionBegan)
    }
    
    // ARセッション中断時の処理
    func sessionWasInterrupted(_ session: ARSession) {
        // 配置済みコンテンツを非表示にする
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
            break
        default:
            break
        }
    }
    
    // リローカライズ実行判定
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        // 配置済みのコンテンツがあるときはリローカライズ処理を行う
        return false
    }
    
    // アンカー更新時
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            if let bodyAnchor = anchor as? ARBodyAnchor {
                // ARBodyAnchorが更新されたときの処理
                bodyTrackingObject.update(with: bodyAnchor)
            }
        }
    }
}
