//
//  InstagramModel.swift
//  ScoutingReporter
//
//  Created by 間嶋大輔 on 2021/11/11.
//

import Foundation
import UIKit

class InstagramModel {
    
    private var mediaURLs: [String] = []
    private var localURLs: [URL] = []
    
    func getMedia(completion: @escaping ([URL]) -> Void) {
        let dispatchGroup = DispatchGroup()
        requestMedia { uiImages in
            for index in uiImages.indices {
                dispatchGroup.enter()
                let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("temp\(index).png")
                if let pngData = uiImages[index].pngData(),
                   ((try? pngData.write(to: url)) != nil) {
                    self.localURLs.append(url)
                }
                dispatchGroup.leave()
            }
            dispatchGroup.notify(queue: .main){
                DispatchQueue.main.async {
                    completion(self.localURLs)
                }
            }
        }
    }
    
    func requestMedia(completion: @escaping ([UIImage]) -> Void) {
        let url = URL(string: "https://graph.instagram.com/me/media?fields=media_type,media_url,caption&access_token=IGQVJXU1YzRWhUSVhjMjlPWkplWXFJcGloQ1hneW0yM2ZA5RmJxZA0JHbmlKT3R1UXZApdTFIS1FWOVFranl6YVl3a0JtNTdMLThTUERjZA3lZAUjBpeXoyR2c2eTkyMUhHS0pCeUNEQ1h3")!
        var request = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else { return }
            do {
                guard let object = try JSONSerialization.jsonObject(with: data, options: []) as? Dictionary<String, Any> else { print("Coudn't parse json object"); return }
                guard let posts = object["data"] as? Array<Dictionary<String, String>> else { print("Coudn't parse json object"); return }
                print(posts)
                for index in posts.indices {
                    if let mediaURL = posts[index]["media_url"] {
                        self.mediaURLs.append(mediaURL)
                    }
                }
                print(self.mediaURLs)
                self.downloadImagesAsync { uiImages in
                    completion(uiImages)
                }
            } catch let error {
                print(error)
            }
        }
        task.resume()
    }
    
    func downloadImagesAsync(completion: @escaping ([UIImage]) -> Void) {
        let dispatchGroup = DispatchGroup()
        var uiImages: [UIImage] = []
        
        for mediaURL in mediaURLs {
            dispatchGroup.enter()
            if let url = URL(string: mediaURL) {
                let session = URLSession(configuration: .default)
                let task = session.dataTask(with: url) { (data, _, _) in
                    var image: UIImage?
                    if let imageData = data {
                        if let image = UIImage(data: imageData) {
                            uiImages.append(image)
                        }
                        dispatchGroup.leave()
                    }
                }
                task.resume()
            }

            }
        dispatchGroup.notify(queue: .main){
            DispatchQueue.main.async {
                completion(uiImages)
            }
        }
    }
}
