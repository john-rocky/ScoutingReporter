//
//  PostItem.swift
//  ScoutingReporter
//
//  Created by 間嶋大輔 on 2021/11/20.
//

import Foundation

struct PostItem {
    let mediaType: MediaType?
    let mediaURL: URL?
    let captions: String?
    var localImageURL: URL?
    let videoURL: URL?
    let albumItems: [AlbumItem]
}

enum MediaType {
    case image
    case video
    case album
}

struct AlbumItem {
    let mediaType: MediaType?
    let url: URL?
}
