//
//  VideoProcessorFractalView.swift
//  MetalPetalDemo
//
//  Created by YuAo on 2021/4/4.
//

import Foundation
import SwiftUI
import AVFoundation
import AVKit
import MetalPetal
import VideoIO

struct VideoProcessorFractalView: View {
    
    class VideoProcessor: ObservableObject {
        @Published var videoPlayer: AVPlayer?
     
        private var videoComposition: MTIVideoComposition?
        private var videoAsset: AVAsset?
        
        private let renderContext = try! MTIContext(device: MTLCreateSystemDefaultDevice()!)
        
        private var exportSession: AssetExportSession?
        
        @Published var exportProgress: Progress?
        
        func updateVideoURL(_ url: URL) {
            let asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
            let presentationSize = asset.presentationVideoSize ?? CGSize(width: 720, height: 720)
            
            let fractalFilter = MTIFractalFilter()
            
            let videoComposition = MTIVideoComposition(asset: asset, context: renderContext, queue: DispatchQueue.main, filter: { request in
                guard let sourceImage = request.anySourceImage else {
                    return MTIImage.black
                }
                fractalFilter.time = Float(request.compositionTime.seconds)
                
                return FilterGraph.makeImage(builder: { output in
                    sourceImage => fractalFilter => output
                })!
            })
            let playerItem = AVPlayerItem(asset: asset)
            playerItem.videoComposition = videoComposition.makeAVVideoComposition()
            self.videoComposition = videoComposition
            videoAsset = asset
            videoPlayer = AVPlayer(playerItem: playerItem)
            videoPlayer?.play()
        }
        
        func export(completion: @escaping (Result<URL, Error>) -> Void) {
            guard let asset = self.videoAsset, let videoComposition = self.videoComposition else {
                return
            }
            exportProgress = nil
            exportSession?.cancel()
            exportSession = nil
            
            var configuration = AssetExportSession.Configuration(fileType: .mp4, videoSettings: .h264(videoSize: videoComposition.renderSize), audioSettings: .aac(channels: 2, sampleRate: 44100, bitRate: 128 * 1000))
            configuration.videoComposition = videoComposition.makeAVVideoComposition()
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
            do {
                let exportSession = try AssetExportSession(asset: asset, outputURL: outputURL, configuration: configuration)
                exportSession.export(progress: { [weak self] progress in
                    self?.exportProgress = progress
                }, completion: { [weak self] error in
                    self?.exportProgress = nil
                    self?.exportSession = nil
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(outputURL))
                    }
                })
                self.exportSession = exportSession
            } catch {
                completion(.failure(error))
            }
        }
        
        deinit {
            exportSession?.cancel()
        }
    }
    
    @StateObject private var videoProcessor = VideoProcessor()

    var body: some View {
        Group {
            if let videoPlayer = videoProcessor.videoPlayer {
                VideoPlayer(player: videoPlayer).toolbar(content: {
                    if let progress = self.videoProcessor.exportProgress {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Exporting...").font(.footnote).foregroundColor(.secondary)
                            ProgressView(value: progress.fractionCompleted).progressViewStyle(LinearProgressViewStyle()).frame(width: 72).smallControlSize()
                        }
                    } else {
                        Button("Export", action: { [videoProcessor] in
                            videoProcessor.export { result in
                                switch result {
                                case .success(let outputURL):
                                    #if os(macOS)
                                    let savePanel = NSSavePanel()
                                    savePanel.nameFieldStringValue = "video." + outputURL.pathExtension
                                    if savePanel.runModal() == .OK, let url = savePanel.url {
                                        do {
                                            try? FileManager.default.removeItem(at: url)
                                            try FileManager.default.moveItem(at: outputURL, to: url)
                                        } catch {
                                            VideoProcessorView.showErrorAlert(error: error)
                                        }
                                    } else {
                                        try? FileManager.default.removeItem(at: outputURL)
                                    }
                                    #else
                                    //For demo purpose only. This is not the best practice of presenting an UIActivityViewController in SwiftUI.
                                    let activityViewController = UIActivityViewController(activityItems: [outputURL], applicationActivities: nil)
                                    activityViewController.completionWithItemsHandler = { _,_,_,_ in
                                        try? FileManager.default.removeItem(at: outputURL)
                                    }
                                    UIApplication.shared.topMostViewController?.present(activityViewController, animated: true, completion: nil)
                                    #endif
                                case .failure(let error):
                                    VideoProcessorFractalView.showErrorAlert(error: error)
                                }
                            }
                        })
                    }
                })
            } else {
                videoPicker
                    .roundedRectangleButtonStyle()
                    .largeControlSize()
                    .toolbar(content: { Spacer() })
            }
        }
        .inlineNavigationBarTitle("Video Processing")
    }
    
    private var videoPicker: some View {
        VideoPicker(title: "Choose Video") { url in
            self.videoProcessor.updateVideoURL(url)
        }
    }
    
    private static func showErrorAlert(error: Error) {
        #if os(macOS)
        NSAlert(error: error).runModal()
        #elseif os(iOS)
        //For demo purpose only. This is not the best practice of presenting an alert in SwiftUI.
        let alertController = UIAlertController(title: error.localizedDescription, message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        UIApplication.shared.topMostViewController?.present(alertController, animated: true, completion: nil)
        #endif
    }
}
