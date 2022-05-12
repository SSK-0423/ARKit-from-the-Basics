//
//  VirtualObject.swift
//  FirstSKAR
//
//  Created by ymtlab on 2022/05/12.
//

import Foundation
import SceneKit
import ARKit

// SCNReferenceNode ファイルから3Dコンテンツを読み込んで表示する際に使用するクラス
// 表示する仮想コンテンツ
class VirtualObject : SCNReferenceNode {
    // このノードに対応するARアンカー
    var anchor: ARAnchor?
    
    // レイキャスト
    var raycast: ARTrackedRaycast?
}

extension VirtualObject {
    // 組み込んだ「Chair.dae」へのURL
    static var chairURL: URL?{
        return Bundle.main.url(forResource: "Chair",
                               withExtension: "dae",
                               subdirectory: "art.scnassets/Chair")
    }
}
