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
    var image = UIImage(named: "kids_at_beach")! //kids_at_beach //hiker //royal
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
        
        makeCoreML()
        
//        self.detectFace(imageView: self.imageView)
//        self.detectFaceWithLandmarks(imageView: imageView) { (faceObservation, faceRect)  in
//
//            guard let landmarks = faceObservation.landmarks else{ return }
//            self.detectAndDrawElement(element: landmarks.leftEye!, faceRect: faceRect)
//            self.detectAndDrawElement(element: landmarks.rightEye!, faceRect: faceRect)
//            self.detectAndDrawElement(element: landmarks.faceContour!, faceRect: faceRect)
//            self.detectAndDrawElement(element: landmarks.innerLips!, faceRect: faceRect)
//            self.detectAndDrawElement(element: landmarks.leftEyebrow!, faceRect: faceRect)
//            self.detectAndDrawElement(element: landmarks.rightEyebrow!, faceRect: faceRect)
//            self.detectAndDrawElement(element: landmarks.medianLine!, faceRect: faceRect)
//            self.detectAndDrawElement(element: landmarks.nose!, faceRect: faceRect)
//
//            guard let rightEyeNormPoints = landmarks.rightEye?.normalizedPoints,
//                let leftEyeNormPoints = landmarks.leftEye?.normalizedPoints else{ return }
//            let rightEye = self.compute(normilizedPoints: rightEyeNormPoints, inRect: faceRect)
//            let leftEye = self.compute(normilizedPoints: leftEyeNormPoints, inRect: faceRect)
//
//            self.drawSunglasses(leftEye: leftEye, rightEye: rightEye, inFaceRect: faceRect)
//        }
    }
    
    //MARK: - Vision
    
    func makeCoreML(){
        struct Face {
            var face: CGRect
            var leftEye = [CGPoint]()
            var rightEye = [CGPoint]()
        }
        
        var faceStruct = [Face]()
        
        let request = VNDetectFaceLandmarksRequest { (req, err) in
            if let err = err{
                print("Failed to detect faces: \(err)")
                return
            }
            
            req.results?.forEach({ (res) in
                guard let faceObservation = res as? VNFaceObservation else{ return }
                
                let rect = self.computeRectFromBoundingBox(boundingBox: faceObservation.boundingBox, inImageView: self.imageView)
                
                let leftEye = self.compute(normilizedPoints: (faceObservation.landmarks?.leftEye?.normalizedPoints)!, inRect: rect)
                let rightEye = self.compute(normilizedPoints: (faceObservation.landmarks?.rightEye?.normalizedPoints)!, inRect: rect)
                faceStruct.append(Face(face: rect, leftEye: leftEye, rightEye: rightEye))
            })
        }
        
        guard let cgImage = imageView.image?.cgImage else{ return }
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        var requests: [VNRequest] = [request]
        
        let leNetPalces = GoogLeNetPlaces()
        
        if let model = try? VNCoreMLModel(for: leNetPalces.model){
            let mlRequest = VNCoreMLRequest(model: model) { (request, error) in
                guard let observations = request.results as? [VNClassificationObservation] else{
                    print("unexpected result type from VNCoreMLRequest")
                    return
                }
                guard let bestResult = observations.first else{
                    print("Did not a valid classification")
                    return
                }
                
                DispatchQueue.main.async {
                    let scene = SceneType(classification: bestResult.identifier)
                    print("Scene: \(scene): \(bestResult.identifier) + \(bestResult.confidence)")
                    switch scene{
                    case .beach: faceStruct.forEach({ (face) in
                        self.drawSunglasses(leftEye: face.leftEye, rightEye: face.rightEye, inFaceRect: face.face)
                    })
                    case .forest: faceStruct.forEach({ (face) in
                        self.drawHat(faceRect: face.face)
                    })
                    case .other:
                        return
                    }
                }
            }
            requests.append(mlRequest)
        }
        
        DispatchQueue.main.async {
            do{
                try handler.perform(requests)
            }catch let err{
                print("Error handling Vision request: \(err)")
            }
        }
    }
    
    
    
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
    
    func detectFaceWithLandmarks(imageView: UIImageView, completion: @escaping ((VNFaceObservation, _ faceRect: CGRect) -> Void)){
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
    
    func detectAndDrawElement(element: VNFaceLandmarkRegion2D, faceRect: CGRect){
        computeAndDrawPoints(normilizedPoints: element.normalizedPoints, inRect: faceRect)
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
//        imageView.layer.borderWidth = 2
//        imageView.layer.borderColor = UIColor.cyan.cgColor
        
        imageView.frame = hatRect
        self.view.addSubview(imageView)
    }
    
    func drawSunglasses(leftEye: [CGPoint], rightEye: [CGPoint], inFaceRect: CGRect){
        let glasses = #imageLiteral(resourceName: "sunglasses")
        print("faceRect: \(inFaceRect)")
        
        let minX = leftEye.reduce(CGFloat.infinity) { (res, point) -> CGFloat in
            return min(res, point.x)
        }
        let maxX = rightEye.reduce(0) { (res, point) -> CGFloat in
            return max(res, point.x)
        }
        let minY = leftEye.reduce(CGFloat.infinity) { (res, point) -> CGFloat in
            return min(res, point.y)
        }
        let maxY = rightEye.reduce(0) { (res, point) -> CGFloat in
            return max(res, point.y)
        }
        
        let width = maxX - minX
        
        let x = (maxX - minX) / 2.0 + minX - width / 2.0
        
        
        let scaledHeight = width / glasses.size.width * glasses.size.height
        
        let y = (maxY - minY) / 2.0 + minY - scaledHeight / 2.0
        
        let imageView = UIImageView(image: glasses)
        imageView.frame = CGRect(x: x + inFaceRect.origin.x,
                                 y: inFaceRect.origin.y + y,
                                 width: width * 1.25,
                                 height: scaledHeight * 1.25)
        
        imageView.contentMode = .scaleAspectFit
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

