//
//  ViewController+Effect.swift
//  RealityAppTemplate
//
//  Created by 山本知仁 on 2022/05/30.
//

import Foundation
import RealityKit
import CoreImage

extension ViewController {
    // ポストプロセスエフェクトの初期化処理
    func preparePostProcessing(device: MTLDevice){
        // CoreImageの初期化
        ciContext = CIContext(mtlDevice: device)
    }
    
    // エフェクト適用処理
    func postProcesing(context: ARView.PostProcessContext) {
        if !isApplyEffect {
            // エフェクトがオフの時
            passThroughEffect(context: context)
            return
        }
        // コミック調フィルタを作成する
        let filter = CIFilter(name: "CIComicEffect")
        
        // 入力画像を設定する
        guard let inputImage = CIImage(mtlTexture: context.sourceColorTexture) else {
            fatalError("Failed to create the input image.")
        }
        
        filter?.setValue(inputImage, forKey: kCIInputImageKey)
        
        // 出力先を取得
        guard let outputImage = filter?.outputImage else {
            fatalError("Failed to get the output image.")
        }
        
        // レンダリング先設定
        let renderDest = CIRenderDestination(mtlTexture: context.compatibleTargetTexture,
                                             commandBuffer: context.commandBuffer)
        
        renderDest.isFlipped = false
        
        // レンダリング開始
        _ = try? ciContext?.startTask(toRender: outputImage, to: renderDest)
    }
    
    // エフェクトを適用せず、入力画像をそのまま出力先に転送する
    func passThroughEffect(context: ARView.PostProcessContext) {
        let encoder = context.commandBuffer.makeBlitCommandEncoder()
        encoder?.copy(from: context.sourceColorTexture,
                      to: context.compatibleTargetTexture)
        encoder?.endEncoding()
    }
    
    // コリジョンイベントの処理
    func onCollisionBegan(_ event: CollisionEvents.Began) {
        // ２つのトリガーボリュームの衝突かを確認
        if event.entityA == bodyTrackingObject.leftTrigger &&
            event.entityB == bodyTrackingObject.rightTrigger {
            // ２つのトリガーボリュームの衝突なので、エフェクトの適用状態を反転させる
            isApplyEffect = !isApplyEffect
        }
    }
}

extension RealityKit.ARView.PostProcessContext {
    // 出力先のMetalのテクスチャーを取得する
    var compatibleTargetTexture: MTLTexture! {
        if self.device.supportsFamily(.apple2) {
            // 出力先のテクスチャーをそのまま使用可能
            return targetColorTexture
        } else {
            // 出力先のテクスチャーのフォーマットを変換する必要がある
            return targetColorTexture.makeTextureView(pixelFormat: .bgra8Unorm)
        }
    }
}
