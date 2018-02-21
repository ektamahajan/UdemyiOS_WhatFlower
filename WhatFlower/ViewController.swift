//
//  ViewController.swift
//  WhatFlower
//
//  Created by Ekta Mahajan on 2/13/18.
//  Copyright © 2018 Ekta Mahajan. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var clickImageView: UIImageView!
    @IBOutlet weak var flowerText: UILabel!
    
    let imagePicker = UIImagePickerController()
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let userImage = info[UIImagePickerControllerEditedImage] as? UIImage{
           // clickImageView.image = userImage
            
            guard let ciimage = CIImage(image: userImage) else{
                fatalError("Unable to convert UIImage to CIImage")
            }
            
            detect(image: ciimage)
            
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(image: CIImage){
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else{
            fatalError("Loading CoreML model failed")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results?.first as? VNClassificationObservation else{
                fatalError("Model failed to process image.")
            }
            
            self.navigationItem.title = results.identifier.capitalized
            self.requestInfo(flowerName: results.identifier)
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do{
            try handler.perform([request])
        }catch{
            print(error)
        }
        
        
    }
    
    func requestInfo(flowerName:String){
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            ]

        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON{ (response) in
            if response.result.isSuccess{
              
                let flowerJSON:JSON = JSON(response.result.value!)
                print(response)
                let pageid = flowerJSON["query"]["pageids"][0].stringValue
                let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                self.clickImageView.sd_setImage(with: URL(string: flowerImageURL))
                self.flowerText.text = flowerDescription
            }
        }
        
    }
    
    @IBAction func cameraClick(_ sender: UIBarButtonItem) {
        
        present(imagePicker, animated: true, completion: nil)
    }
    
}

