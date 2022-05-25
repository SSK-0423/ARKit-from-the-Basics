//
//  ContentView.swift
//  RealityApp
//
//  Created by ymtlab on 2022/05/24.
//

import SwiftUI
import RealityKit

struct ContentView : View {
    var body: some View {
        return ARViewContainer().edgesIgnoringSafeArea(.all)
    }
}

struct ARViewContainer: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = ARContainerViewController
    
    func makeUIViewController(context: Context) -> ARContainerViewController {
        return ARContainerViewController()
    }
    
    
    func updateUIViewController(_ uiViewController: ARContainerViewController, context: Context) {
    }
    
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
