//
//  ContentView.swift
//  ScoutingReporter
//
//  Created by 間嶋大輔 on 2021/11/10.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ARViewControllerContainer()
            .edgesIgnoringSafeArea(.all) // 全画面表示
    }
}

struct ARViewControllerContainer: UIViewControllerRepresentable {

    func makeUIViewController(context: UIViewControllerRepresentableContext<ARViewControllerContainer>) -> UIViewController {
        let viewController = ARViewController()
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<ARViewControllerContainer>) {
    }

    func makeCoordinator() -> ARViewControllerContainer.Coordinator {
        return Coordinator()
    }

    class Coordinator {

    }
}
