//
//  VideoListViewModel.swift
//  VidiFrame
//
//  Created by 이상훈 on 4/11/25.
//

import Foundation

class VideoListViewModel {

    // MARK: - Properties
    private(set) var videoURLs: [URL] = []

    // MARK: - Callback
    var onVideosUpdated: (() -> Void)?

    // MARK: - Public Methods
    func loadSavedVideos() {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }

        do {
            var fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            fileURLs = fileURLs.filter { ["mov", "mp4"].contains($0.pathExtension.lowercased()) }

            if fileURLs.isEmpty {
                fileURLs = [
                    URL(fileURLWithPath: "/example/path/video1.mp4"),
                    URL(fileURLWithPath: "/example/path/video2.mov")
                ]
            }

            self.videoURLs = fileURLs
            self.onVideosUpdated?()

        } catch {
            print("Error loading videos: \(error)")
        }
    }

    func videoName(at index: Int) -> String {
        guard index < videoURLs.count else { return "Unnamed" }
        return videoURLs[index].lastPathComponent
    }

    func numberOfVideos() -> Int {
        return videoURLs.count
    }
}
