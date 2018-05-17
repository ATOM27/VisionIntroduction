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
        self.detectLandmarks(imageView: imageView) { (faceObservation, faceRect)  in
            self.detectAndDrawLeftEye(faceObservation: faceObservation, faceRect: faceRect)
            self.detectAndDrawRightEye(faceObservation: faceObservation, faceRect: faceRect)
            self.detectAndDrawFaceContour(faceObservation: faceObservation, faceRect: faceRect)
            self.detectAndDrawInnerLips(faceObservation: faceObservation, faceRect: faceRect)
            self.detectAndDrawLeftEyebrow(faceObservation: faceObservation, faceRect: faceRect)
            self.detectAndDrawRightEyebrow(faceObservation: faceObservation, faceRect: faceRect)
            self.detectAndDrawMedianLine(faceObservation: faceObservation, faceRect: faceRect)
            self.detectAndDrawNose(faceObservation: faceObservation, faceRect: faceRect)
        }
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
    
    func detectLandmarks(imageView: UIImageView, completion: @escaping ((VNFaceObservation, _ faceRect: CGRect) -> Void)){
        let faceRequest = VNDetectFaceLandmarksRequest { (req, err) in
            if let err = err{
                print("Failed to detect landmarks: \(err)")
            }
            
            req.results?.forEach({ (res) in
                guard let faceObservation = res as? VNFaceObservation else{ return }
                let rect = self.computeRectFromBoundingBox(boundingBox: faceObservation.boundingBox, inImageView: imageView)
                completion(faceObservation, rect)
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
    
    func detectAndDrawLeftEye(faceObservation: VNFaceObservation, faceRect: CGRect){
        guard let landmarks = faceObservation.landmarks else{ return }
        guard let leftEyePoints = landmarks.leftEye?.normalizedPoints else{ return }
        computeAndDrawPoints(normilizedPoints: leftEyePoints, inRect: faceRect)
    }
    
    func detectAndDrawRightEye(faceObservation: VNFaceObservation, faceRect: CGRect){
        guard let landmarks = faceObservation.landmarks else{ return }
        guard let rightEyePoints = landmarks.rightEye?.normalizedPoints else{ return }
        computeAndDrawPoints(normilizedPoints: rightEyePoints, inRect: faceRect)
    }
    
    func detectAndDrawFaceContour(faceObservation: VNFaceObservation, faceRect: CGRect){
        guard let landmarks = faceObservation.landmarks else{ return }
        guard let faceCounturPoints = landmarks.faceContour?.normalizedPoints else{ return }
        computeAndDrawPoints(normilizedPoints: faceCounturPoints, inRect: faceRect)
    }
    
    func detectAndDrawInnerLips(faceObservation: VNFaceObservation, faceRect: CGRect){
        guard let landmarks = faceObservation.landmarks else{ return }
        guard let innerLipsPoints = landmarks.innerLips?.normalizedPoints else{ return }
        computeAndDrawPoints(normilizedPoints: innerLipsPoints, inRect: faceRect)
    }
    
    func detectAndDrawLeftEyebrow(faceObservation: VNFaceObservation, faceRect: CGRect){
        guard let landmarks = faceObservation.landmarks else{ return }
        guard let leftEyebrowPoints = landmarks.leftEyebrow?.normalizedPoints else{ return }
        computeAndDrawPoints(normilizedPoints: leftEyebrowPoints, inRect: faceRect)
    }
    
    func detectAndDrawRightEyebrow(faceObservation: VNFaceObservation, faceRect: CGRect){
        guard let landmarks = faceObservation.landmarks else{ return }
        guard let rightEyebrowPoints = landmarks.rightEyebrow?.normalizedPoints else{ return }
        computeAndDrawPoints(normilizedPoints: rightEyebrowPoints, inRect: faceRect)
    }
    
    func detectAndDrawMedianLine(faceObservation: VNFaceObservation, faceRect: CGRect){
        guard let landmarks = faceObservation.landmarks else{ return }
        guard let medianLinePoints = landmarks.medianLine?.normalizedPoints else{ return }
        computeAndDrawPoints(normilizedPoints: medianLinePoints, inRect: faceRect)
    }
    
    func detectAndDrawNose(faceObservation: VNFaceObservation, faceRect: CGRect){
        guard let landmarks = faceObservation.landmarks else{ return }
        guard let nosePoints = landmarks.nose?.normalizedPoints else{ return }
        computeAndDrawPoints(normilizedPoints: nosePoints, inRect: faceRect)
    }
    
    //MARK: - Help methods
    
    func computeAndDrawPoints(normilizedPoints: [CGPoint], inRect faceRect: CGRect){
        var points = self.compute(normilizedPoints: normilizedPoints, inRect: faceRect)
        
        let path = UIBezierPath()
        path.move(to: points.first!)
        
        points.removeFirst()
        points.forEach({ (point) in
            path.addLine(to: point)
        })
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = UIColor.green.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.frame.origin = faceRect.origin
        imageView.layer.addSublayer(shapeLayer)
    }
    
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
    
    private func compute(normilizedPoints: [CGPoint], inRect rect: CGRect) -> [CGPoint]{
        var points: [CGPoint] = []
        
        normilizedPoints.forEach { (normPoint) in
            let point = CGPoint(x: normPoint.x * rect.size.width,
                                y: ( 1 - normPoint.y) * rect.size.height)
            points.append(point)
        }
        return points
    }

}

