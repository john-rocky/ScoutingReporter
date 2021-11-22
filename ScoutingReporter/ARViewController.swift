//
//  ARViewController.swift
//  ScoutingReporter
//
//  Created by 間嶋大輔 on 2021/11/11.
//

import Foundation
import UIKit
import RealityKit
import ARKit
import Combine
import AVFoundation

class ARViewController: UIViewController {
    
    private var model = InstagramModel()
    private var cancellables: [Cancellable] = []

    private var arView: ARView!
    private var faceAnchor: AnchorEntity?
    private var postEntities: [Entity] = []
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupARView()
        
        self.model.getMedia { imageURLs,postItems  in
            print(imageURLs.count)
            self.displayPostEntities(imageURLs: imageURLs, postItems: postItems)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let isActiveSub = arView.scene.subscribe(to: SceneEvents.Update.self) { event in
        }
        cancellables.append(isActiveSub)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancellables.forEach { Cancellable in
            Cancellable.cancel()
        }
    }
    
    
    // MARK: Set Up
    
    func setupARView() {
        arView = ARView(frame: view.bounds)
        view.addSubview(arView)
        
        let config = ARFaceTrackingConfiguration()
        arView.session.run(config, options: [])
        
        faceAnchor = AnchorEntity(.face)
        arView.scene.anchors.append(faceAnchor!)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tap))
        arView.addGestureRecognizer(tapGesture)
        arView.renderOptions.insert(.disableFaceOcclusions)
        
        let filter = UIView(frame: view.bounds)
        filter.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        view.addSubview(filter)

    }
    
    // MARK: Gesture
    
    @objc func tap(sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: arView)
        if let tappedEntity = arView.entity(at: tapLocation) as? ModelEntity {
            tappedEntity.move(to: Transform(scale: [2,2,2]), relativeTo: faceAnchor, duration: 2, timingFunction: .easeInOut)
        }
    }
    
    // MARK: Post Entities
    
    func displayPostEntities(imageURLs urls: [URL], postItems: [PostItem]) {
        generatePostEntities(imageURLs: urls, postItems: postItems) { [self] in
            radialAnimation(centerOfCircle: [0,0,-1], radius: 0.2, numberOfEntities: postEntities.count)
        }
    }
    
    func generatePostEntities(imageURLs urls: [URL], postItems: [PostItem],completion: @escaping () -> Void) {
//        for index in urls.indices {
//            let postPlane = ModelEntity(mesh: .generateBox(size: [0.1,0.1,0.05]))
//            postPlane.generateCollisionShapes(recursive: true)
//
//            let url = urls[index]
//            if let texture = try? TextureResource.load(contentsOf: url) {
//                var imageMaterial = UnlitMaterial()
//                imageMaterial.baseColor = MaterialColorParameter.texture(texture)
//                postPlane.model?.materials = [imageMaterial]
//                postEntities.append(postPlane)
        //            }
        //            print(postEntities.count)
        //            completion()
        //        }
        let dispatchGroup = DispatchGroup()
        for index in postItems.indices {
            dispatchGroup.enter()
            let postPlane = ModelEntity(mesh: .generateBox(size: [0.1,0.1,0.05]))
            postPlane.generateCollisionShapes(recursive: true)
            
            let postItem = postItems[index]
            
            switch postItem.mediaType {
            case .image:
                if let url = postItem.localImageURL,let texture = try? TextureResource.load(contentsOf: url) {
                    var imageMaterial = UnlitMaterial()
                    imageMaterial.baseColor = MaterialColorParameter.texture(texture)
                    postPlane.model?.materials = [imageMaterial]
                    postEntities.append(postPlane)
                    dispatchGroup.leave()
                } else{
                    dispatchGroup.leave()
                }
            case .video:
                if let url = postItem.videoURL {
                    let asset = AVURLAsset(url: url) // URLからAVAssetを作る
                    let playerItem = AVPlayerItem(asset: asset) // AVAssetでAVPlayerItemを作る
                    let player = AVPlayer(playerItem: playerItem)
                    player.actionAtItemEnd = AVPlayer.ActionAtItemEnd.none;
                    NotificationCenter.default.addObserver(self,
                                                           selector: #selector(ARViewController.didPlayToEnd),
                                                           name: NSNotification.Name("AVPlayerItemDidPlayToEndTimeNotification"),
                                                           object: player.currentItem)
                    let videoMaterial = VideoMaterial(avPlayer: player)
                    postPlane.model?.materials = [videoMaterial]
                    player.play()
                    postEntities.append(postPlane)
                    dispatchGroup.leave()
                } else {
                    dispatchGroup.leave()
                }
            case .album:
                if let firstItemOfAlbum = postItem.albumItems.first {
                    switch firstItemOfAlbum.mediaType {
                    case .image:
                        if let url = postItem.localImageURL,let texture = try? TextureResource.load(contentsOf: url) {
                            var imageMaterial = UnlitMaterial()
                            imageMaterial.baseColor = MaterialColorParameter.texture(texture)
                            postPlane.model?.materials = [imageMaterial]
                            postEntities.append(postPlane)
                            dispatchGroup.leave()
                        } else {
                            dispatchGroup.leave()
                        }
                    case .video:
                        if let url = firstItemOfAlbum.url {
                            let asset = AVURLAsset(url: url)
                            let playerItem = AVPlayerItem(asset: asset)
                            let player = AVPlayer(playerItem: playerItem)
                            player.actionAtItemEnd = AVPlayer.ActionAtItemEnd.none;
                            NotificationCenter.default.addObserver(self,
                                                                   selector: #selector(ARViewController.didPlayToEnd),
                                                                   name: NSNotification.Name("AVPlayerItemDidPlayToEndTimeNotification"),
                                                                   object: player.currentItem)
                            let videoMaterial = VideoMaterial(avPlayer: player)
                            postPlane.model?.materials = [videoMaterial]
                            player.play()
                            postEntities.append(postPlane)
                            dispatchGroup.leave()
                        } else {
                            dispatchGroup.leave()
                        }
                    default:break
                    }
                } else {
                    dispatchGroup.leave()
                }
            default:
                dispatchGroup.leave()
            }
            
            print(postEntities.count)
        }
        dispatchGroup.notify(queue: .main){
            completion()
        }
    }
    
    @objc func didPlayToEnd(notification: NSNotification) {
        let item: AVPlayerItem = notification.object as! AVPlayerItem
        item.seek(to: CMTime.zero, completionHandler: nil)
    }
    
    func radialAnimation(centerOfCircle:SIMD3<Float>, radius: Float, numberOfEntities: Int) {
        for index in postEntities.indices {
            let postEntity = postEntities[index]
            postEntity.position = centerOfCircle
            
            let angleOfEntity = Float(index) / Float(numberOfEntities) * 2.0 * Float(Double.pi)
            let angle = -0.5 * Float(Double.pi) + angleOfEntity
            let x = cos(angle) * radius
            let y = sin(angle) * radius
            let destination:SIMD3<Float> = [x,y,0]
            faceAnchor?.addChild(postEntity)
            Timer.scheduledTimer(withTimeInterval: Double(index)*Double(0.2)+1, repeats: false) { timer in
                postEntity.move(to: Transform(translation:destination), relativeTo: self.faceAnchor ?? nil, duration: 0.2, timingFunction: .easeInOut)
            }
        }
    }
}
