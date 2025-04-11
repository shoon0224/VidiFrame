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
    
    func saveVideo(_ sourceURL: URL, completion: (() -> Void)? = nil) {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }

        let destinationURL = documentsDirectory.appendingPathComponent(sourceURL.lastPathComponent)

        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                print("파일 이미 존재함: \(destinationURL.lastPathComponent)")
            } else {
                try fileManager.copyItem(at: sourceURL, to: destinationURL)
                videoURLs.append(destinationURL)
            }
            completion?()
        } catch {
            print("파일 저장 실패: \(error)")
        }
    }
}
