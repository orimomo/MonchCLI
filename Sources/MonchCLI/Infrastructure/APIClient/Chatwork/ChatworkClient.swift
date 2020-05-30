//
//  ChatworkClient.swift
//  MonchCLI
//
//  Created by 安宅正之 on 2020/05/30.
//

import Foundation

struct ChatworkClient {
    private let config: Config.Chatwork

    init(config: Config.Chatwork) {
        self.config = config
    }

    func send(_ message: Message) {
        let baseUrl = "https://api.chatwork.com/v2"
        let urlString = "\(baseUrl)/rooms/\(message.roomId)/messages"
        guard let url = URL(string: urlString) else { return }
        let httpBody: Data
        do {
            httpBody = try XWWWFormUrlEncoder().encode(message)
        } catch {
            fatalError(error.localizedDescription)
        }
        let request: URLRequest = { url, httpBody in
            var request = URLRequest.init(url: url)
            request.httpMethod = "POST"
            request.setValue(config.token, forHTTPHeaderField: "X-ChatWorkToken")
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = httpBody
            return request
        }(url, httpBody)

        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            guard let response = response as? HTTPURLResponse else { fatalError("No Response") }
            switch response.statusCode {
            case 200..<300: break
            default:
                fatalError(response.description)
            }

            guard let data = data else { return }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            do {
                let decoded = try decoder.decode(CreateMessageResponse.self, from: data)
                print("MessageId: \(decoded.messageId)")
            } catch let decodeError {
                fatalError(decodeError.localizedDescription)
            }
        }
        task.resume()
        semaphore.wait()
    }
}