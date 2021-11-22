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
    var postItems:[PostItem] = []
    
    func getMedia(completion: @escaping ([URL],[PostItem]) -> Void) {
        let dispatchGroup = DispatchGroup()
        requestMedia { uiImages, postItems in
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
                    completion(self.localURLs,self.postItems)
                }
            }
        }
    }
    
    func requestMedia(completion: @escaping ([UIImage],[PostItem]) -> Void) {
        let url = URL(string: "https://graph.instagram.com/me/media?fields=media_type,media_url,caption&access_token=IGQVJXZA043a3VMNmNuSjNyRnVoZAFNXVEg0MmZAvTHBkanVWNGlpU1ByRXltUnRWUHo5T0JlQzlBTWxRdkQwci0ybU1GZAHEweGFwRUtIaGY4OUI3NFlBSThxUzhkaFFuNjVjMVlXZADJB")!
        var request = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else { return }
            do {
                guard let object = try JSONSerialization.jsonObject(with: data, options: []) as? Dictionary<String, Any> else { print("Coudn't parse json object"); return }
                guard let posts = object["data"] as? Array<Dictionary<String, String>> else { print("Coudn't parse json object"); return }
                                print(posts)
                
                let dispatchGroup = DispatchGroup()
                
                for index in posts.indices {
                    
                    dispatchGroup.enter()
                    
                    var mediaType:MediaType? = nil
                    var mediaURL:URL? = nil
                    var captions:String? = nil
                    var localURL:URL? = nil
                    var videoURL:URL? = nil
                    var albumItems:[AlbumItem] = []
                    
                    if let mediaURLString = posts[index]["media_url"] {
                        mediaURL = URL(string: mediaURLString)
                        self.mediaURLs.append(mediaURLString)
                    }
                    
                    if let captionsString = posts[index]["caption"] {
                        captions = captionsString
                    }
                    
                    if let mediaTypeString = posts[index]["media_type"] {
                        switch mediaTypeString {
                        case "IMAGE": mediaType = .image
                            if let url = mediaURL {
                                let session = URLSession(configuration: .default)
                                let task = session.dataTask(with: url) { (data, _, _) in
                                    var image: UIImage?
                                    if let imageData = data {
                                        if let image = UIImage(data: imageData) {
                                            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("temp\(index).png")
                                            if let pngData = image.pngData(),
                                               ((try? pngData.write(to: url)) != nil) {
                                                localURL = url
                                                dispatchGroup.leave()
                                            } else {
                                                dispatchGroup.leave()
                                            }
                                        } else {
                                            dispatchGroup.leave()
                                        }
                                    } else {
                                        dispatchGroup.leave()
                                    }
                                }
                                task.resume()
                            }
                        case "VIDEO": mediaType = .video
                            videoURL = mediaURL
                            dispatchGroup.leave()
                        case "CAROUSEL_ALBUM": mediaType = .album
                            let albumDispatchGroup = DispatchGroup()
                            
                            if let mediaID:String = posts[index]["id"] {
                                let url = URL(string:
                                                "https://graph.instagram.com/\(mediaID)/children?fields=media_type,media_url&access_token=IGQVJXZA043a3VMNmNuSjNyRnVoZAFNXVEg0MmZAvTHBkanVWNGlpU1ByRXltUnRWUHo5T0JlQzlBTWxRdkQwci0ybU1GZAHEweGFwRUtIaGY4OUI3NFlBSThxUzhkaFFuNjVjMVlXZADJB")!
                                let request = URLRequest(url: url)
                                let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                                    guard let data = data else { return }
                                    do {
                                        guard let object = try JSONSerialization.jsonObject(with: data, options: []) as? Dictionary<String, Any> else { print("Coudn't parse json object"); return }
                                        if let albumPosts = object["data"] as? Array<Dictionary<String, String>> {
                                        for albumIndex in albumPosts.indices {
                                            albumDispatchGroup.enter()
                                            var albumMediaType: MediaType? = nil
                                            var albumMediaURL: URL?
                                            if let albumMediaTypeString = albumPosts[albumIndex]["media_type"] {
                                                switch albumMediaTypeString {
                                                case "IMAGE":
                                                    albumMediaType = .image
                                                    if let albumImageURLString = albumPosts[albumIndex]["media_url"],let albumImageURL = URL(string: albumImageURLString) {
                                                        let albumImageSession = URLSession(configuration: .default)
                                                        let task = albumImageSession.dataTask(with: albumImageURL) { (data, _, _) in
                                                            if let imageData = data {
                                                                if let image = UIImage(data: imageData) {
                                                                    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("tempalbum\(albumIndex).png")
                                                                    if let pngData = image.pngData(),
                                                                       ((try? pngData.write(to: url)) != nil) {
                                                                        albumMediaURL = url
                                                                        let albumItem = AlbumItem(mediaType: albumMediaType, url: albumMediaURL)
                                                                        albumItems.append(albumItem)
                                                                        albumDispatchGroup.leave()
                                                                    } else {
                                                                        let albumItem = AlbumItem(mediaType: albumMediaType, url: albumMediaURL)
                                                                        albumItems.append(albumItem)
                                                                        albumDispatchGroup.leave()
                                                                    }
                                                                } else {
                                                                    let albumItem = AlbumItem(mediaType: albumMediaType, url: albumMediaURL)
                                                                    albumItems.append(albumItem)
                                                                    albumDispatchGroup.leave()
                                                                }
                                                            } else {
                                                                let albumItem = AlbumItem(mediaType: albumMediaType, url: albumMediaURL)
                                                                albumItems.append(albumItem)
                                                                albumDispatchGroup.leave()
                                                            }
                                                        }
                                                        task.resume()
                                                    }
                                                case "VIDEO":
                                                    albumMediaType = .video
                                                    if let albumVideoURLString = albumPosts[albumIndex]["media_url"] as? String,let albumVideoURL = URL(string: albumVideoURLString) {
                                                        albumMediaURL = albumVideoURL
                                                    }
                                                    let albumItem = AlbumItem(mediaType: albumMediaType, url: albumMediaURL)
                                                    albumItems.append(albumItem)
                                                    
                                                    albumDispatchGroup.leave()
                                                default:
                                                    albumMediaType = nil
                                                    let albumItem = AlbumItem(mediaType: albumMediaType, url: albumMediaURL)
                                                    albumItems.append(albumItem)
                                                    albumDispatchGroup.leave()
                                                }
                                            }
                                        }
                                        } else {
                                            print("Coudn't parse json object")
                                        }
                                        albumDispatchGroup.notify(queue: .main){
                                            dispatchGroup.leave()
                                        }
                                    } catch let error {
                                        print(error)
                                    }
                                }
                                task.resume()
                            } else {
                                dispatchGroup.leave()
                            }
                        default: mediaType = nil
                        }
                    }
                    dispatchGroup.notify(queue: .main){
                        let postItem = PostItem(mediaType: mediaType, mediaURL: mediaURL, captions: captions,localImageURL: localURL, videoURL: videoURL, albumItems: albumItems)
                        self.postItems.append(postItem)
                        print(self.postItems)
                    }
                }
                
                self.downloadImagesAsync { uiImages in
                    completion(uiImages, self.postItems)
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
