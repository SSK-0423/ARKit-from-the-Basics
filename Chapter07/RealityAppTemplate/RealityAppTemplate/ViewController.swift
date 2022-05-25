//
//  ViewController.swift
//  RealityAppTemplate
//
//  Created by ymtlab on 2022/05/25.
//

import UIKit
import RealityKit
import ARKit

class ViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet var arView: ARView!
    var coachingOverlay = ARCoachingOverlayView()
    var planeAnchor: AnchorEntity?
    var boxModel: ModelEntity?
    var postObject: VirtualObject?
    
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
    
    // ARセッションをリセットする
    func resetTracking() {
        // ビューのシーン認識オプションを設定する
        arView.environment.sceneUnderstanding.options = [.occlusion,.physics,.receivesLighting]
        
        let config = ARWorldTrackingConfiguration()
        
        // シーン再構築を有効化する
        // シーン再構築が可能なデバイスかを調べる
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
//            arView.debugOptions = [.showSceneUnderstanding]
        }
        
        // 水平面を検出する
        config.planeDetection = [.horizontal]
        // 環境テクスチャマッピングを有効化する
        config.environmentTexturing = .automatic
        
        // 人物によるオクルージョンを行う
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth){
            config.frameSemantics.insert(.personSegmentationWithDepth)
        }
        // セッションを開始する
        arView.session.run(config, options: [.removeExistingAnchors,.resetTracking])
        
        // 平面アンカーエンティティを追加する
        planeAnchor = AnchorEntity(plane: .horizontal)
        arView.scene.addAnchor(planeAnchor!)
        
        // ボックスを生成する
        addBox()
        
        // ポストを追加する
        addPost()
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
}
