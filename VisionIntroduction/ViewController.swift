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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        guard let image = UIImage(named: "aaa") else{ return }
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        
        imageView.backgroundColor = .red
        
        let scaledHeight = view.frame.width / image.size.width * image.size.height
        imageView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: scaledHeight)
        self.view.addSubview(imageView)
        
        let request = VNDetectFaceRectanglesRequest { (req, err) in
            
            if let err = err{
                print("Failed to detect faces: \(err)")
                return
            }
            
            req.results?.forEach({ (res) in
                guard let faceObservation = res as? VNFaceObservation else{ return }
                print(faceObservation.boundingBox)
                
                let size = CGSize(width: faceObservation.boundingBox.width * imageView.bounds.width,
                                  height: faceObservation.boundingBox.height * imageView.bounds.height)
                let origin = CGPoint(x: faceObservation.boundingBox.origin.x * imageView.bounds.width,
                                     y: (1 - faceObservation.boundingBox.origin.y) * imageView.bounds.height - size.height)
                
                let redView = UIView()
                redView.backgroundColor = UIColor.red
                redView.alpha = 0.3
                redView.frame = CGRect(origin: origin, size: size)
                self.view.addSubview(redView)
                
            })
        }
        
        guard let cgImage = image.cgImage else{ return }
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do{
            try handler.perform([request])
        }catch let error{
            print("Failed to perform request: \(error)")
        }
    }
}

