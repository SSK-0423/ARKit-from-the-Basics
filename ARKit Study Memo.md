#  基礎から学ぶARKit 勉強メモ
#### 仮想オブジェクトの配置
1. SceneKitがノードの位置にコンテンツをレンダリング ⇨ 
2. ARアンカーでコンテンツの位置をARKitに知らせる ⇨ 
3. ARセッションに追加(物理空間にコンテンツを配置) 
4. 表示

#### ARSessionObserver
下記のプロトコルがARSessionObserverプロトコルを継承している
- ARSessionDelegate
- ARSCNViewDelegate
- ARSKViewDelegate
