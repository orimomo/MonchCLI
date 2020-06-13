//
//  GitHubUser.swift
//  MonchCLI
//
//  Created by 安宅正之 on 2020/06/07.
//

import Foundation

struct GitHubUser: GithubApiResponse, Identifiable, Equatable, Encodable {
    let id: Int
    let login: GitHubLogin

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}