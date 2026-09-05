//
//  EditingManager.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 30.11.2024.
//

import Foundation
import UIKit

enum PostRequestError: Error {
    case invalidSelection
    case outOfStock
}

class EditingManager {
    
    //MARK: - Restoration
    func restorations(apiKey: String, decompress: String, upscale: String, imageURL: String, image: UIImage?, completions: @escaping ((Result<String, Error>)) ->()) {
        
        guard let url = URL(string: "https://api.claid.ai/v1-beta1/image/edit") else {
            print("Invalid URL")
            return
        }
        
        let requestBody: [String: Any] = [
            "input": imageURL,
            "operations": [
                "restorations": [
                    "upscale": upscale,
                    "decompress": decompress,
                    "polish": true
                ],
                
                "resizing": [
                    "width": "200%",
                    "height": "200%"
                ]
            ],
            
            "output": [
                "format": [
                    "type": "jpeg",
                    "quality": 90
                ]
            ]
        ]
        
        postRequestForEditing(url: url, apiKey: apiKey, requestBody: requestBody) { result in
            switch result {
            case .success(let imageURL):
                completions(.success(imageURL))
            case .failure(let error):
                completions(.failure(error))
            }
        }
    }
    
    
    //MARK: - Resizing
    func resizing(apiKey: String, imageURL: String, width: String, height: String, fit: String, completions: @escaping ((Result<String, Error>)) ->()) {
        
        guard let url = URL(string: "https://api.claid.ai/v1-beta1/image/edit") else {
            print("Invalid URL")
            return
        }
        
        let requestBody: [String: Any] = [
            "input": imageURL,
            "operations": [
                "resizing": [
                    "width": width,
                    "height": height,
                    "fit": fit
                ]
            ]
        ]
        
        postRequestForEditing(url: url, apiKey: apiKey, requestBody: requestBody) { result in
            switch result {
            case .success(let imageURL):
                completions(.success(imageURL))
            case .failure(let error):
                completions(.failure(error))
            }
        }
    }
    
    
    func resizingInt(apiKey: String, imageURL: String, width: Int, height: Int, fit: String, completions: @escaping ((Result<String, Error>)) ->()) {
        
        guard let url = URL(string: "https://api.claid.ai/v1-beta1/image/edit") else {
            print("Invalid URL")
            return
        }
        
        let requestBody: [String: Any] = [
            "input": imageURL,
            "operations": [
                "resizing": [
                    "width": width,
                    "height": height,
                    "fit": fit
                ]
            ]
        ]
        
        postRequestForEditing(url: url, apiKey: apiKey, requestBody: requestBody) { result in
            switch result {
            case .success(let imageURL):
                completions(.success(imageURL))
            case .failure(let error):
                completions(.failure(error))
            }
        }
    }
    
    
    func resizingAuto(apiKey: String, imageURL: String, height: Int, fit: String, completions: @escaping ((Result<String, Error>)) ->()) {
        
        guard let url = URL(string: "https://api.claid.ai/v1-beta1/image/edit") else {
            print("Invalid URL")
            return
        }
        
        let requestBody: [String: Any] = [
            "input": imageURL,
            "operations": [
                "resizing": [
                    "width": "auto",
                    "height": height,
                    "fit": fit
                ]
            ]
        ]
        
        postRequestForEditing(url: url, apiKey: apiKey, requestBody: requestBody) { result in
            switch result {
            case .success(let imageURL):
                completions(.success(imageURL))
            case .failure(let error):
                completions(.failure(error))
            }
        }
    }
    
    
    func resizingEmpty(apiKey: String, imageURL: String, width: Int, fit: String, completions: @escaping ((Result<String, Error>)) ->()) {
        
        guard let url = URL(string: "https://api.claid.ai/v1-beta1/image/edit") else {
            print("Invalid URL")
            return
        }
        
        let requestBody: [String: Any] = [
            "input": imageURL,
            "operations": [
                "resizing": [
                    "width": width,
                    "fit": fit
                ]
            ]
        ]
        
        postRequestForEditing(url: url, apiKey: apiKey, requestBody: requestBody) { result in
            switch result {
            case .success(let imageURL):
                completions(.success(imageURL))
            case .failure(let error):
                completions(.failure(error))
            }
        }
    }
    
    
    
    //MARK: - Padding
    func padding(apiKey: String, imageURL: String, backgroundRemove: Bool, top: String, bottom: String, left: String, right: String, completions: @escaping ((Result<String, Error>)) ->()) {
        
        guard let url = URL(string: "https://api.claid.ai/v1-beta1/image/edit") else {
            print("Invalid URL")
            return
        }
        
        let requestBody: [String: Any] = [
            "input": imageURL,
            "operations": [
                "background": [
                    "remove": backgroundRemove
                ],
                "padding": "\(top)px \(bottom)px \(left)px \(right)px"
            ]
        ]
        
        postRequestForEditing(url: url, apiKey: apiKey, requestBody: requestBody) { result in
            switch result {
            case .success(let imageURL):
                completions(.success(imageURL))
            case .failure(let error):
                completions(.failure(error))
            }
        }
    }
    
    
    //MARK: - Color adjustment
    func colorAdjustments(apiKey: String, imageURL: String, hdr: Int, exposure: Int, saturation: Int, contrast: Int, sharpness: Int, completions: @escaping ((Result<String, Error>)) ->()) {
        
        guard let url = URL(string: "https://api.claid.ai/v1-beta1/image/edit") else {
            print("Invalid URL")
            return
        }
        
        let requestBody: [String: Any] = [
            "input": imageURL,
            "operations": [
                "adjustments": [
                    "hdr": hdr,
                    "exposure": exposure,
                    "saturation": saturation,
                    "contrast": contrast,
                    "sharpness": sharpness
                ]
            ]
        ]
        
        postRequestForEditing(url: url, apiKey: apiKey, requestBody: requestBody) { result in
            switch result {
            case .success(let imageURL):
                completions(.success(imageURL))
            case .failure(let error):
                completions(.failure(error))
            }
        }
    }
    
    
    //MARK: - Background editing
    func backgroundEditing(apiKey: String, imageURL: String, color: String, completions: @escaping ((Result<String, Error>)) ->()) {
        guard let url = URL(string: "https://api.claid.ai/v1-beta1/image/edit") else {
            print("Invalid URL")
            return
        }
        
        let requestBody: [String: Any] = [
            
            "input": imageURL,
            "operations": [
                "background": [
                    "remove": true,
                    "color": color
                ]
            ]
        ]
        
        postRequestForEditing(url: url, apiKey: apiKey, requestBody: requestBody) { result in
            switch result {
            case .success(let imageURL):
                completions(.success(imageURL))
            case .failure(let error):
                completions(.failure(error))
            }
        }
    }
    
    
    //MARK: - Generating images by prompt
    func generatingImagesByPrompt(apiKey: String, prompt: String, numberOfImages: Int, guidanceScale: Float, completions: @escaping ((Result<String, Error>)) ->()) {
        
        guard let url = URL(string: "https://api.claid.ai/v1-beta1/image/generate") else {
            print("Invalid URL")
            return
        }
        
        let requestBody: [String: Any] = [
            "input": prompt,
            "options": [
                "number_of_images": numberOfImages,
                "guidance_scale": guidanceScale
            ]
        ]
        
        postRequestForImageGeneration(url: url, apiKey: apiKey, requestBody: requestBody) { result in
            switch result {
            case .success(let imageURL):
                completions(.success(imageURL))
            case .failure(let error):
                completions(.failure(error))
            }
        }
    }
    
    
    //MARK: - Post requests
    func postRequestForEditing(url: URL, apiKey: String, requestBody: [String: Any], completions: @escaping ((Result<String, Error>)) ->()) {
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
            print("Failed to serialize JSON")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Request failed: \(error.localizedDescription)")
                completions(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                completions(.failure(PostRequestError.invalidSelection))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("Request failed with status code: \(httpResponse.statusCode)")
                completions(.failure(PostRequestError.invalidSelection))
                return
            }
            
            guard let data = data else {
                print("No data received")
                completions(.failure(PostRequestError.invalidSelection))
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let data = jsonResponse["data"] as? [String: Any],
                   let output = data["output"] as? [String: Any],
                   let tmpUrl = output["tmp_url"] as? String {
                    completions(.success(tmpUrl))
                } else {
                    print("Error: No tmp_url in response")
                    completions(.failure(PostRequestError.invalidSelection))
                }
            } catch {
                print("Error parsing response: \(error)")
                completions(.failure(error))
            }
        }
        task.resume()
    }
    
    
    func postRequestForImageGeneration(url: URL, apiKey: String, requestBody: [String: Any], completions: @escaping ((Result<String, Error>)) ->()) {
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
            print("Failed to serialize JSON")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Request failed: \(error.localizedDescription)")
                completions(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                completions(.failure(PostRequestError.invalidSelection))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("Request failed with status code: \(httpResponse.statusCode)")
                completions(.failure(PostRequestError.invalidSelection))
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let data = jsonResponse["data"] as? [String: Any],
                   let output = data["output"] as? [[String: Any]],
                   let firstOutput = output.first,
                   let tmpURL = firstOutput["tmp_url"] as? String {
                    for i in output {
                        if let tmpURL = i["tmp_url"] as? String {
                            completions(.success(tmpURL) )
                        }
                    }
                } else {
                    print("Failed to parse tmp_url")
                    
                }
            } catch {
                print("Error parsing response: \(error)")
                completions(.failure(error))
            }
        }
        task.resume()
    }
    
    
    
    //MARK: Upload image for editing
    func uploadImage(apiKey: String, image: UIImage, completions: @escaping (String) -> ()) {
        // Set the URL for the API endpoint
        guard let url = URL(string: "https://api.claid.ai/v1-beta1/image/edit/upload") else { return }
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Boundary string for multipart form data
        let boundary = "boundary"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Create the body data
        let body = createMultipartBody(boundary: boundary, image: image)
        
        // Set the body
        request.httpBody = body
        
        // Create the URLSession
        let session = URLSession.shared
        
        // Perform the request
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            
            if let data = data {
                // Assuming the server returns a JSON object with a URL in the response
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let data = jsonResponse["data"] as? [String: Any],
                       let output = data["output"] as? [String: Any],
                       let tmpUrl = output["tmp_url"] as? String {
                        completions(tmpUrl)
                    } else {
                        print("Error: No tmp_url in response")
                    }
                } catch {
                    print("Error parsing response: \(error)")
                }
            }
        }
        
        // Start the task
        task.resume()
    }
    
    
    func createMultipartBody(boundary: String, image: UIImage) -> Data {
        var body = Data()
        
        // Convert UIImage to Data
        if let imageData = image.jpegData(compressionQuality: 1.0) {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"the_image.jpg\"\r\n")
            body.append("Content-Type: image/jpeg\r\n\r\n")
            body.append(imageData)
            body.append("\r\n")
        }
        
        // Add the JSON data
        let jsonData: [String: Any] = [
            "operations": [
                "resizing": [
                    "width": "50%",
                    "height": "50%",
                    "fit": "bounds"
                ],
            ]
        ]
        
        
        if let json = try? JSONSerialization.data(withJSONObject: jsonData, options: .prettyPrinted) {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"data\"\r\n")
            body.append("Content-Type: application/json\r\n\r\n")
            body.append(json)
            body.append("\r\n")
        }
        
        body.append("--\(boundary)--\r\n")
        return body
    }
}


//MARK: Extensions
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
