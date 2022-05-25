//
//  VirtualObject.swift
//  RealityAppTemplate
//
//  Created by ymtlab on 2022/05/25.
//

import RealityKit
import ARKit
import Combine

class VirtualObject {
    // モデルに対するアンカー
    var modelAnchor: AnchorEntity
    // モデル情報
    var modelEntity: ModelEntity?
    // 非同期読み込みで使用するオブジェクト
    var cancellable: AnyCancellable?
    
    // イニシャライザ
    init(modelAnchor: AnchorEntity){
        self.modelAnchor = modelAnchor
    }
    
    // イスのモデルデータを非同期で読み込む
    func loadModel(name: String, nameExtension: String, completion: @escaping (Bool) -> Void){
        // 指定されたファイルへのURLを取得する
        guard let url = Bundle.main.url(forResource: name, withExtension: nameExtension) else {
            // ファイルがみつからない
            completion(false)
            return
        }
        
        // ファイルから非同期で読み込む
        cancellable = Entity.loadModelAsync(contentsOf: url, withName: nil).sink(receiveCompletion: {loadCompletion in
            // 完了処理
            if case let .failure(error) = loadCompletion{
                // 読み込み時にエラーが発生した場合
                print(error.localizedDescription)
                completion(false)
            } else {
                // 成功
                completion(true)
            }
        }, receiveValue: {[weak self] model in
            // モデル情報取得
            self?.modelEntity = model
            // モデル用のアンカーに追加
            self?.modelAnchor.addChild(model)
        })
    }
}
