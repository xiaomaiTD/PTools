//
//  PTVision.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 23/4/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Vision
import VisionKit

@available(iOS 14.0,*)
public class PTVision: NSObject {
    static let share = PTVision()
    
    //MARK: OCR查找文字方法(UIImage)
    ///OCR查找文字方法(UIImage)
    /// - Parameters:
    ///   - image: 图片
    ///   - revision: Vision版本(VNRecognizeTextRequestRevision2 iOS14,VNRecognizeTextRequestRevision3 iOS16)
    ///   - resultBlock: 回调
    public func findText(withImage image:UIImage,
                         revision:Int = VNRecognizeTextRequestRevision2,
                         resultBlock:((_ resultText:String,_ textObservations:[VNRecognizedTextObservation])->Void)?) {
        PTGCDManager.gcdGobal {
            let textDetectionRequest = VNRecognizeTextRequest { request, error in
                if error != nil {
                    PTNSLogConsole(error!.localizedDescription)
                } else {
                    guard let observations = request.results as? [VNRecognizedTextObservation] else {
                        PTNSLogConsole("some errors")
                        return
                    }
                    
                    PTGCDManager.gcdMain {
                        let maximumCandidates = 1
                        var resultText = ""
                        for observation in observations {
                            let candidates = observation.topCandidates(maximumCandidates)
                            for candidate in candidates {
                                resultText += candidate.string + "\n"
                            }
                        }
                        PTNSLogConsole(resultText)
                        if resultBlock != nil {
                            resultBlock!(resultText,observations)
                        }
                    }
                }
            }
            
            textDetectionRequest.recognitionLanguages = ["zh-cn"]
            textDetectionRequest.recognitionLevel = .accurate
            textDetectionRequest.revision = revision
            
            PTGCDManager.gcdMain {
                if let cgImage = image.cgImage {
                    let handler = VNImageRequestHandler(cgImage: cgImage,options: [:])
                    
                    guard let  _ = try? handler.perform([textDetectionRequest]) else {
                        PTNSLogConsole("Could not perform text Detection request!!!!!")
                        return
                    }
                }
            }
        }
    }
    
    //MARK: OCR查找文字方法(UIImageView)
    ///OCR查找文字方法(UIImageView)
    /// - Parameters:
    ///   - imageView: 图片
    ///   - revision: Vision版本(VNRecognizeTextRequestRevision2 iOS14,VNRecognizeTextRequestRevision3 iOS16)
    ///   - resultBlock: 回调
    public func findText(withImageView imageView:UIImageView,
                         revision:Int = VNRecognizeTextRequestRevision2,
                         resultBlock:((_ resultText:String)->Void)?) {
        var textLayers = [CAShapeLayer]()
        imageView.layer.sublayers?.forEach({ layer in
            layer.removeFromSuperlayer()
        })
        
        self.findText(withImage:imageView.image!,revision: revision) { resultText, textObservations in
            if resultBlock != nil {
                resultBlock!(resultText)
            }

            textLayers = self.addShapeToText(observations: textObservations, textImageView: imageView)
            
            for layer in textLayers {
                imageView.layer.addSublayer(layer)
            }
        }
    }
    
    private func addShapeToText(observations:[VNRecognizedTextObservation],textImageView:UIImageView) -> [CAShapeLayer] {
        let layers:[CAShapeLayer] = observations.map { observation in
            let w = observation.boundingBox.size.width * textImageView.bounds.width
            let h = observation.boundingBox.size.height * textImageView.bounds.height
            let x = observation.boundingBox.origin.x * textImageView.bounds.width
            let y = abs((observation.boundingBox.origin.y * (textImageView.bounds.height)) - textImageView.bounds.height) - h

            let layer = CAShapeLayer()
            layer.frame = CGRect(x: x, y: y, width: w, height: h)
            layer.borderColor = UIColor.random.cgColor
            layer.borderWidth = 1
            layer.cornerRadius = 2
            return layer
        }
        return layers
    }
}