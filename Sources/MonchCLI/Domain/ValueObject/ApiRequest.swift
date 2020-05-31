//
//  ApiRequest.swift
//  MonchCLI
//
//  Created by 安宅正之 on 2020/05/31.
//

import Foundation

protocol ApiRequest: Encodable {
    associatedtype Response: ApiResponse
    var path: String { get }
    func makeURLRequest(baseUrl: String) -> URLRequest?
}

protocol ApiResponse: Decodable {}
