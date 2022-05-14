//
//  ViewController.swift
//  FirstSKAR
//
//  Created by ymtlab on 2022/05/11.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate,ARSessionDelegate
{
    // SceneKitのビュークラス
    @IBOutlet var sceneView: ARSCNView!
    
    // 椅子のコンテンツ
    var chair: VirtualObject?
    
    //
    var sessionStatusLabel: UILabel?
    
    // オーバーレイビュー
    let coachingOverlay = ARCoachingOverlayView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        // デバッグ情報の表示
        sceneView.showsStatistics = false
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // Create a new scene
        let scene = SCNScene()
                
        // Set the scene to the view
        // ビューに表示する3Dコンテンツの設定
        sceneView.scene = scene
        
        // ジェスチャーを設定する
        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(didTap(_:)))
        
        sceneView.addGestureRecognizer(tap)
        
        addSessionStatusLabel()
        
        setupCoachingOverlay()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resetTracking()
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // 水平面を検出する
        // ARセッションの開始前に行う
        configuration.planeDetection = [.horizontal]
        
        // Run the view's session
        sceneView.session.run(configuration)
        
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    // アンカーが追加された時に呼ばれるデリゲートメソッド
    func renderer(_ renderer: SCNSceneRenderer,didAdd node: SCNNode, for anchor: ARAnchor){
        // 平面検出された時に追加されるARアンカーかどうかを、ARPlaneAnchorかどうかで判断する
        // キャストの成否で判断する
        guard let _ = anchor as? ARPlaneAnchor else {
            return
        }
        
        DispatchQueue.main.async {
            self.sessionStatusLabel?.text = "Plane was detected (SceneKit)"
            print("Plane was detected (SceneKit)")
        }
    }
    
    // アンカーが削除されたときに呼ばれるデリゲートメソッド
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor){
        // 検出された平面用のアンカーがどうかを調べる
        guard let _ = anchor as? ARPlaneAnchor else {
            return
        }
        
        DispatchQueue.main.async {
            self.sessionStatusLabel?.text = "Plane was removed (SceneKit)"
            print("Plane was removed (SceneKit)")
        }
    }
    
    // ARアンカーの情報が更新されたときの処理
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if chair != nil && node == chair {
            // 更新後のARアンカーの位置を取得
            let translation = anchor.transform.columns.3
            chair?.simdPosition = [translation.x,translation.y,translation.z]
            chair?.anchor = anchor
            
            DispatchQueue.main.async {
                print("ARAnchor was updated (Chair)")
            }
        }
    }
    
    private func placeChair(_ chair: VirtualObject){
        // カメラの焦点 0.8m 離れた地点に移動する
        chair.position = SCNVector3(x: 0, y: 0, z: -0.8)
        
        // 親ノードがなけらばシーングラフに配置されていない
        if chair.parent == nil {
            // ルートノードの真下に追加する
            sceneView.scene.rootNode.addChildNode(chair)
        }
        
        // ARアンカーを移動する
        updateAnchor(of: chair)
    }
    
    // ARアンカーの位置をノードの位置に移動する
    private func updateAnchor(of object: VirtualObject){
        // すでにARアンカーを設定していたら削除する
        if let anchor = object.anchor {
            sceneView.session.remove(anchor: anchor)
        }
        
        // ノードと同じ場所にARアンカーを作成する
        let newAnchor = ARAnchor(transform: object.simdTransform)
        object.anchor = newAnchor
        // ARアンカーをARセッションに追加する
        sceneView.session.add(anchor: newAnchor)
    }
    
    // タップされたと認識された時に呼ばれるメソッド
    // 形式はこれで固定されている
    @objc func didTap(_ gesture: UITapGestureRecognizer){
        // ジェスチャーが完了している時に実行
        if gesture.state == .ended {
            // タップされた場所を取得
            let location = gesture.location(in: sceneView)
            print("tapped : (\(location.x),\(location.y))")
            
            // レイキャストクエリーを作成する
            guard let raycastQuery = sceneView.raycastQuery(from: location, // 2次元のスクリーン座標
                                                            allowing: .estimatedPlane,  // レイキャストを許可する平面の種類
                                                            alignment: .horizontal) // 水平、垂直、両方のいずれかを指定
            else {
                return
            }
            
            // レイキャストクエリーを実行して物理空間での座標を計算する
            // ARRaycastResult カメラから近い順にレイとの交点情報が格納されている
            let raycastResults = sceneView.session.raycast(raycastQuery)
            
            if raycastResults.count > 0 {
                // 読み込み済みの椅子を削除する
                if chair != nil {
                    removeChair()
                }
                
                chair = loadChair()
                
                if chair != nil {
                    // 位置を設定する
                    set3DPosition(with: raycastResults[0], of: chair!)
                    // 継続した認識を行う
                    createTrackedRaycast(raycastQuery, for: chair!)
                }
            }
        }
    }
    
    // レイキャストで検出した場所に移動する
    func set3DPosition(with raycastResult: ARRaycastResult,of object: VirtualObject){
        // worldTransform 4*4の行列 位置、回転、拡大・縮小の情報が格納(アフィン変換の行列と一緒)
        object.simdTransform = raycastResult.worldTransform
        updateAnchor(of: object)
    }
    
    // 継続したレイキャストの作成
    func createTrackedRaycast(_ query: ARRaycastQuery, for object: VirtualObject){
        // 繰り返し実行されるレイキャストを作成
        sceneView.session.trackedRaycast(query) {
            raycastResults in if raycastResults.count > 0 {
                self.set3DPosition(with: raycastResults[0], of: object)
            }
        }
    }
    
    // 椅子をロードする
    func loadChair() -> VirtualObject? {
        var object: VirtualObject?
        
        //「Chair.dae」へのURLを取得する
        if let url = VirtualObject.chairURL {
            // [Chair.dae]を読み込んで「VirtualObject」を作る
            object = VirtualObject(url: url)
            
            if object != nil {
                // ファイルを読む
                object?.load()
                // 配置する
                placeChair(object!)
            }
        }
        
        return object
    }
    
    // 椅子を削除する
    func removeChair() {
        chair?.raycast?.stopTracking()
        
        if let anchor = chair?.anchor {
            sceneView.session.remove(anchor: anchor)
        }
        
        chair?.removeFromParentNode()
        chair = nil
    }
    
    func addSessionStatusLabel() {
        // sceneViewの下端に配置する
        let labelFrame = CGRect(x: 0,
                                y: sceneView.bounds.height - 21,
                                width: sceneView.bounds.width,
                                height: 21)
        // ラベルを作成する
        sessionStatusLabel = UILabel(frame: labelFrame)
        guard sessionStatusLabel != nil else {
            return
        }
        
        sessionStatusLabel?.translatesAutoresizingMaskIntoConstraints = false
        sceneView.addSubview(sessionStatusLabel!)
        
        // 背景色を白色にする
        sessionStatusLabel?.backgroundColor = .white
        
        // フォントを固定する
        sessionStatusLabel?.font = .systemFont(ofSize: 17.0)
        
        // 常に下端に横幅一杯で表示する
        NSLayoutConstraint.activate([
            sessionStatusLabel!.centerXAnchor.constraint(equalTo: sceneView.centerXAnchor),
            sessionStatusLabel!.widthAnchor.constraint(equalTo: sceneView.widthAnchor),
            sessionStatusLabel!.bottomAnchor.constraint(equalTo: sceneView.safeAreaLayoutGuide.bottomAnchor),
            sessionStatusLabel!.heightAnchor.constraint(equalToConstant: 21.0)
        ])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        sceneView.session.pause()
    }
    
    
    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    // セッションでエラーが発生すると呼ばれる
    // error 発生したエラー情報
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        sessionStatusLabel?.text = "ARSession failed"
        print("ARSession failed")
        
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
            // エラーメッセージの表示
            let alert = UIAlertController(title: "ARSession Failed",
                                          message: message,
                                          preferredStyle: .alert)
            // アラートが閉じられた後の処理
            let reset = UIAlertAction(title: "Reset Tracking", style: .default) {
                _ in self.resetTracking()
            }
            alert.addAction(reset)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // ARSessionDelegateのメソッド
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]){
        for anchor in anchors {
            // 平面のアンカーかどうかを判定
            if let _ = anchor as? ARPlaneAnchor {
                sessionStatusLabel?.text = "Plane was detected (ARSession)"
                print("Plane was detected (ARSession)")
            }
        }
    }
    
    // ARSessionDelegateのメソッド
    // アンカー削除時に呼ばれる
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]){
        for anchor in anchors {
            // 平面のアンカーかどうかを判定
            if let _ = anchor as? ARPlaneAnchor {
                sessionStatusLabel?.text = "Plane was removed (ARSession)"
                print("Plane was removed (ARSession)")
            }
        }
    }
    
    // カメラのトラッキング精度が変わった時に呼ばれる
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        // トラッキング精度を調べて、ラベルとコンソールに出力する
        switch camera.trackingState {
        case .notAvailable:
            sessionStatusLabel?.text = "Tracking State: Not available"
            print("Tracking State: Not available")
            
        case .normal:
            sessionStatusLabel?.text = "Traking State: Normal"
            print("Tracking State: Normal")
            chair?.isHidden = false
            
        case .limited(.initializing):
            sessionStatusLabel?.text = "Tracking State: Limited(Initializing)"
            print("Tracking State: Limited(Initializing)")
            
        case .limited(.relocalizing):
            sessionStatusLabel?.text = "Tracking State: Limited(Relocalizing)"
            print("Tracking State: Limited(Relocalizing)")
            
        case .limited(.excessiveMotion):
            sessionStatusLabel?.text = "Tracking State: Limited(excessiveMotion)"
            print("Tracking State: Limited(excessiveMotion)")
            
        case .limited(.insufficientFeatures):
            sessionStatusLabel?.text = "Tracking State: Limited(InsufficientFeatures)"
            print("Tracking State: Limited(InsufficientFeatures)")
            break
            
        case .limited(_):
            break
        }
    }
    
    // 割り込みによりセッションが中断されたときに呼ばれる
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        sessionStatusLabel?.text = "Session was interrupted"
        print("Session was interrupted")
        
        chair?.isHidden = true
    }
    
    // 中断されたセッションが再開されたときに呼ばれる
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        sessionStatusLabel?.text = "Session interruption ended"
        print("Session interruption ended")
    }
    
    // リローカライズを行うかを返す
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
    
    // トラッキングリセット
    func resetTracking(){
        let configuration = ARWorldTrackingConfiguration()
        // 水平面を検出する
        configuration.planeDetection = [.horizontal]
        sceneView.session.run(configuration,options: [.resetTracking,.removeExistingAnchors])
    }
}
