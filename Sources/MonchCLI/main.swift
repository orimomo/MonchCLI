import Foundation
import ArgumentParser

struct Monch: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "レビュー依頼を楽にするコマンドライン・ツール",
        version: "0.2.0",
        subcommands: [Review.self],
        defaultSubcommand: Review.self
    )
    static let filePath = #file
}

Monch.main()

