//
//  ContentView.swift
//  DanMu
//
//  Created by 香饽饽zizizi on 2024/3/28.
//

import SwiftUI
import AVKit
import Vision
import CoreImage.CIFilterBuiltins

class DisplayLinkHandler: NSObject {
    var callback: (() -> Void)?

    @objc func displayLinkCallback() {
        callback?()
    }
}

struct ContentView: View {
    @State private var player: AVPlayer?
    @State private var videoOutput: AVPlayerItemVideoOutput?
    @State private var outputImage: UIImage?

    var body: some View {
        ZStack {
            if let player = player {
                VStack {
                    VideoPlayer(player: player)
                        .overlay {
                            Rectangle()
                                .fill(.clear)
                                .overlay {
                                    VStack {
                                        DanMuView(text: "弹幕大军，出击！")
                                        DanMuView(text: "66666666666666")
                                        DanMuView(text: "233333")
                                        DanMuView(text: "hahahahahaha")
                                        DanMuView(text: "666")
                                        DanMuView(text: "23333333333333")
                                        DanMuView(text: "哈哈哈🤣")
                                    }
                                }
                                .mask {
                                    if let image = outputImage {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                    } else {
                                        Rectangle()
                                    }
                                }
                        }
                        .ignoresSafeArea()
                }
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            tearDownPlayer()
        }
        .onReceive(NotificationCenter.default.publisher(for: AVPlayerItem.didPlayToEndTimeNotification), perform: { _ in
            tearDownPlayer()
            setupPlayer()
        })
    }

    func setupPlayer() {
        guard let url = Bundle.main.url(forResource: "girl", withExtension: "mp4") else {
            return }

        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        let videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: nil)
        playerItem.add(videoOutput)

        player.play()

        let displayLinkHandler = DisplayLinkHandler()
        displayLinkHandler.callback = {
            displayLinkHandlerCallback()
        }
        let displayLink = CADisplayLink(target: displayLinkHandler, selector: #selector(DisplayLinkHandler.displayLinkCallback))
        displayLink.add(to: .current, forMode: .default)


        self.player = player
        self.videoOutput = videoOutput
    }

    func tearDownPlayer() {
        player?.pause()
        player = nil
        videoOutput = nil
    }

    func displayLinkHandlerCallback() {
        guard let videoOutput = videoOutput else { return }

        let currentTime = CMTimeGetSeconds(videoOutput.itemTime(forHostTime: CACurrentMediaTime()))
        let time = CMTime(seconds: currentTime, preferredTimescale: 600)

        guard let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil) else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            performSegmentation(pixelBuffer)
        }
    }

    func performSegmentation(_ pixelBuffer: CVPixelBuffer) {
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .fast
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)

        try? handler.perform([request])

        guard let maskPixelBuffer = request.results?.first?.pixelBuffer else { return }

        blend(origin: pixelBuffer, mask: maskPixelBuffer)
    }

    func blend(origin: CVPixelBuffer, mask: CVPixelBuffer) {
        let originImage = CIImage(cvPixelBuffer: origin)
        var maskImage = CIImage(cvPixelBuffer: mask)

        let clearImage = CIImage(color: .clear).cropped(to: maskImage.extent)

        let scaleX = originImage.extent.width / maskImage.extent.width
        let scaleY = originImage.extent.height / maskImage.extent.height

        maskImage = maskImage.transformed(by: .init(scaleX: scaleX, y: scaleY))

        let blendFilter = CIFilter.blendWithMask()
        blendFilter.inputImage = clearImage
        blendFilter.backgroundImage = originImage
        blendFilter.maskImage = maskImage

        guard let targetIamge = blendFilter.outputImage else { return }

        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(targetIamge, from: targetIamge.extent) else { return }
        self.outputImage = UIImage(cgImage: cgImage)
    }
}

#Preview {
    ContentView()
}
