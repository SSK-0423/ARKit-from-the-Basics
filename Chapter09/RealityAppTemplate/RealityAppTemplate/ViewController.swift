//
//  ViewController.swift
//  RealityAppTemplate
//
//  Created by ymtlab on 2022/05/25.
//

import UIKit
import RealityKit
import ARKit
import Combine

class ViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet var arView: ARView!
    var coachingOverlay = ARCoachingOverlayView()
    var planeAnchor: AnchorEntity?
    var virtualOjbects: [VirtualObject] = []
    var pressObject: VirtualObject?
    var eventUpdate: Cancellable?
    
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
        
        // タップジェスチャーを設定する
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tap)
        
        // 長押しジェスチャーを設定する
        let longPress = UILongPressGestureRecognizer(target: self,
                                                     action: #selector(handleLongPress(_:)))
        arView.addGestureRecognizer(longPress)
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
        // シーン再構築されたメッシュに対して、コリジョンなどを適用する
        arView.environment.sceneUnderstanding.options = [.physics,.occlusion,.collision,.receivesLighting]
        
        let config = ARWorldTrackingConfiguration()
        
        // シーン再構築を有効化する
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        
        // 環境テクスチャーマッピングを有効化する
        config.environmentTexturing = .automatic
        
        // 水平面を検出する
        config.planeDetection = [.horizontal]
        // セッションを開始する
        arView.session.run(config, options: [.removeExistingAnchors,.resetTracking])
        
        // アンカーエンティティ追加
        planeAnchor = addPlane()
        // 球を２つ配置する
        virtualOjbects.append(addVirtualObject(name: "Sphere",
                                               nameExtension: "usdz",
                                               position: [-0.015,0.4,0.0],
                                               plane: planeAnchor!))
        virtualOjbects.append(addVirtualObject(name: "Sphere",
                                               nameExtension: "usdz",
                                               position: [0.015,0.4,0.0],
                                               plane: planeAnchor!))
        
        // フレーム更新イベントを受け取る
        eventUpdate = arView.scene.subscribe(to: SceneEvents.Update.self,
                                             onUpdateFrame)
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
