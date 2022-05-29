//
//  File.swift
//  
//
//  Created by クワシマ・ユウキ on 2022/05/29.
//

import Foundation
import AVKit
import AVFoundation
import Photos
import CoreImage.CIFilterBuiltins

#if canImport(UIKit)
import UIKit
private typealias Color = UIColor
private typealias Font = UIFont
#endif

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
private typealias Color = NSColor
private typealias Font = NSFont
#endif

open class VideoSubtitles {
    
    var _assetExport: AVAssetExportSession!
    
    var asset: AVAsset!
    
    public init() {
        
    }
    
    var texts: [(text: String, fontName: String, fontSize: Float, startTime: Float, endTime: Float, x: Float, y: Float)] = []
    
    open func setVideo(videoName: String, extensionName: String) {
        let movieURL = Bundle.main.url(forResource: videoName, withExtension: extensionName)
        asset = AVAsset(url: movieURL!)
    }
    
    open func insertText(text: String, fontName: String, fontSize: Float, startTime: Float, endTime: Float, x: Float, y: Float){
        texts.append((text, fontName, fontSize, startTime, endTime, x, y))
    }
    
    open func compose() -> AVMutableVideoComposition {
        let composition = AVMutableVideoComposition(asset: asset) { [self] request in
            
            var composited: CIImage = request.sourceImage
            
            let time = CMTimeGetSeconds(request.compositionTime)
            
            for t in texts {
//                if t.startTime < Float(time) && t.endTime > Float(time) {
                    let attributes = [
                        NSAttributedString.Key.foregroundColor : Color.blue,
                        NSAttributedString.Key.font : Font(name: t.fontName, size: CGFloat(t.fontSize))!
                    ]
                    
                    let text = NSAttributedString(string: "test", attributes: attributes)
                    
                    let textFilter = CIFilter.attributedTextImageGenerator()
                    textFilter.text = text
                    textFilter.scaleFactor = 4.0
                    
                    let centerHorizontal = (request.renderSize.width - textFilter.outputImage!.extent.width)/2
                    let moveTextTransform = CGAffineTransform(translationX: CGFloat(t.x), y: CGFloat(t.y))
                    let positionedText = textFilter.outputImage!.transformed(by: moveTextTransform)
                    
                    composited = positionedText.composited(over: composited)
//                }
            }
        
            
            
            
            
            
            request.finish(with: composited, context: nil)
        }
        
        return composition
    }
    
    open func export(composition: AVMutableVideoComposition) {
        _assetExport = AVAssetExportSession.init(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        // 合成用コンポジションを設定
        _assetExport?.videoComposition = composition

        // エクスポートファイルの設定
        let exportPath: String = NSHomeDirectory() + "/tmp/createdMovie.mov"
        let exportUrl: URL = URL(fileURLWithPath: exportPath)
        _assetExport?.outputFileType = AVFileType.mp4
        _assetExport?.outputURL = exportUrl
        _assetExport?.shouldOptimizeForNetworkUse = true

        // ファイルが存在している場合は削除
        if FileManager.default.fileExists(atPath: exportPath) {
            try! FileManager.default.removeItem(atPath: exportPath)
        }

        // エクスポート実行
        _assetExport?.exportAsynchronously(completionHandler: {() -> Void in
            if self._assetExport?.status == AVAssetExportSession.Status.failed {
                // 失敗した場合
                print("failed:", self._assetExport?.error)
            }
            if self._assetExport?.status == AVAssetExportSession.Status.completed {
                // 成功した場合
                print("completed")
                // カメラロールに保存
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: exportUrl)
                })
            }
        })
    }
    
    open func getPlayerItem() -> AVPlayerItem {
        let item = AVPlayerItem(asset: asset)
        return item
    }
}
