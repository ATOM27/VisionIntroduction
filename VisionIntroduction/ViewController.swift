//
//  ViewController.swift
//  VisionIntroduction
//
//  Created by Eugene  Mekhedov on 15.05.2018.
//  Copyright © 2018 Eugene  Mekhedov. All rights reserved.
//

import UIKit
import Vision


class ViewController: UIViewController {
    //MARK: - Properties
    var image = UIImage(named: "image")!
    var imageView: UIImageView!

    //MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // ImageView setup
        imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .red
        
        let scaledHeight = view.frame.width / image.size.width * image.size.height
        imageView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: scaledHeight)
        self.view.addSubview(imageView)
        
//        self.detectFace(imageView: self.imageView)
        self.detectLandmarks(imageView: imageView)
    }
    
    //MARK: - Vision
    private func detectFace(imageView: UIImageView){
        let request = VNDetectFaceRectanglesRequest { (req, err) in
            
            if let err = err{
                print("Failed to detect faces: \(err)")
                return
            }
            
            req.results?.forEach({ (res) in
                guard let faceObservation = res as? VNFaceObservation else{ return }
                
                let rect = self.computeRectFromBoundingBox(boundingBox: faceObservation.boundingBox, inImageView: imageView)
                self.drawRectangle(rect: rect)
                self.drawHat(faceRect: rect)
                
                
            })
        }
        
        guard let cgImage = imageView.image?.cgImage else{ return }
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do{
            try handler.perform([request])
        }catch let error{
            print("Failed to perform request: \(error)")
        }
    }
    
    private func detectLandmarks(imageView: UIImageView){
        let faceRequest = VNDetectFaceLandmarksRequest { (req, err) in
            if let err = err{
                print("Failed to detect landmarks: \(err)")
            }
            
            req.results?.forEach({ (res) in
                guard let faceObservation = res as? VNFaceObservation else{ return }
                
                guard let landmarks = faceObservation.landmarks else{ return }
                guard let normalizedPoints = landmarks.leftEye?.normalizedPoints else{ return }
                var leftEyePoints = self.compute(normilizedPoints: normalizedPoints, inImageView: imageView)
                
                let path = UIBezierPath()
                path.move(to: leftEyePoints.first!)
                
                leftEyePoints.removeFirst()
                leftEyePoints.forEach({ (point) in
                    path.addLine(to: point)
                })
                
                path.close()
                
                let shapeLayer = CAShapeLayer()
                shapeLayer.path = path.cgPath
                shapeLayer.strokeColor = UIColor.green.cgColor
                
                imageView.layer.addSublayer(shapeLayer)
            })
        }
        
        guard let cgImage = imageView.image?.cgImage else{ return }
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([faceRequest])
        } catch let err {
            print("Failed to perform request: \(err)")
        }
    }
    
    //MARK: - Help methods
    private func drawHat(faceRect: CGRect) {
        let hat = #imageLiteral(resourceName: "Archer_Hat")

        let hatSize = hat.size
        let headSize = faceRect.size

        let hatWidthForHead = (3.0 / 2.0) * headSize.width
        let hatRatio = hatWidthForHead / hatSize.width
        let scaleTransform = CGAffineTransform(scaleX: hatRatio,
                                               y: hatRatio)
        let adjustedHatSize = hatSize.applying(scaleTransform)

        let hatRect = CGRect(
            x: faceRect.midX - (adjustedHatSize.width / 2.0),
            y: faceRect.minY - adjustedHatSize.height,
            width: adjustedHatSize.width,
            height: adjustedHatSize.height)

        let imageView = UIImageView(image: hat)
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.cyan.cgColor
        
        imageView.frame = hatRect
        self.view.addSubview(imageView)
    }
    
    private func drawRectangle(rect: CGRect){
        let redView = UIView()
        redView.layer.borderColor = UIColor.red.cgColor
        redView.layer.borderWidth = 2
        
        redView.frame = rect
        
        self.view.addSubview(redView)
    }
    
    private func computeRectFromBoundingBox(boundingBox: CGRect, inImageView imageView: UIImageView) -> CGRect{
        let size = CGSize(width: boundingBox.width * imageView.bounds.width,
                          height: boundingBox.height * imageView.bounds.height)
        let origin = CGPoint(x: boundingBox.origin.x * imageView.bounds.width,
                             y: (1 - boundingBox.origin.y) * imageView.bounds.height - size.height)
        return CGRect(origin: origin, size: size)
    }
    
    private func compute(normilizedPoints: [CGPoint], inImageView imageView: UIImageView) -> [CGPoint]{
        var points: [CGPoint] = []
        
        normilizedPoints.forEach { (normPoint) in
            let point = CGPoint(x: (1 - normPoint.x) * imageView.bounds.width,
                                y: ( 1 - normPoint.y) * imageView.bounds.height)
            points.append(point)
        }
        return points
    }
}

