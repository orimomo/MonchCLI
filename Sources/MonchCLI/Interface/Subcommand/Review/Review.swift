//
//  Review.swift
//  MonchCLI
//
//  Created by 安宅正之 on 2020/06/07.
//

import Foundation
import ArgumentParser

extension Monch {
    struct Review: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "PR のレビューを依頼する")

        mutating func run() {
            let config = ConfigRepository().fetch()

            let semaphore = DispatchSemaphore(value: 0)
            selectPullRequests(with: config) { [self] pullRequest in
                self.requestCodeReview(for: pullRequest, with: config) {
                    print("タスクを振りました。")
                    semaphore.signal()
                }
            }
            semaphore.wait()
        }

        private func selectPullRequests(with config: Config, completionHandler: @escaping (PullRequest) -> Void) {
            let request = ListPullRequestsRequest()
            let githubClient = GithubClient(config: config.github)
            githubClient.send(request) { pullRequests in
                    let listPullRequest = pullRequests
                    .prefix(8)
                    .enumerated()
                    .map({ (offset, pullRequest) in
                        "[\(offset)] \(pullRequest.title)"
                    })
                    .joined(separator: "\n")

                print(listPullRequest)
                print("\n> PR を番号で選択してください: ")
                guard let read = readLine(),
                    let index = Int(read) else { return }

                let pullRequest = pullRequests[index]
                completionHandler(pullRequest)
            }
        }

        private func requestCodeReview(for pullRequest: PullRequest, with config: Config, completionHandler: @escaping () -> Void) {
            let listReviewers = config.reviewers
                .enumerated()
                .map { (offset, reviewer) in
                    "[\(offset)] \(reviewer.name)"
                }
                .joined(separator: "\n")

            print(listReviewers)
            print("\n> レビュワーを選んでください: ")
            guard let read = readLine() else { return }

            let text = """
            \(pullRequest.title)
            \(pullRequest.htmlUrl)

            レビューをお願いします (please)
            """

            let listDeadline = """
            [0] 急いでいます。今日中で!!
            [1] 時間のある時にやって欲しいです。二営業日以内!
            [2] 急いでいません。でも忘れてもらっては困ります。二週間以内に。
            """
            print(listDeadline)
            print("\n> しめ切りを設定してください: ")
            guard let readDeadline = readLine() else { return }
            var dateComponent = DateComponents()
            switch readDeadline {
            case "0":
                dateComponent.hour = 2
            case "1":
                switch Calendar.current.dateComponents([.weekday], from: Date()).weekday {
                case 1, 2, 3, 4: // Sunday, Monday, Tuesday, Wednesday
                    dateComponent.day = 2
                case 5, 6: // Thursday, Friday
                    dateComponent.day = 4
                case 7: // Saturday
                    dateComponent.day = 3
                default:
                    fatalError("NO DAY of WEEK")
                }
            case "2":
                dateComponent.day = 14
            default:
                fatalError("No DEADLINE")
            }
            guard let deadline = Calendar.current.date(byAdding: dateComponent, to: Date()) else { return }

            let assignees = read
                .split(separator: ",")
                .map(String.init)
                .compactMap(Int.init)
                .map { config.reviewers[$0] }

            //        let request = CreateMessageRequest(roomId: config.chatwork.roomId, text: "Hello, This is MonchCLI!")
            let request = CreateTaskRequest(roomId: config.chatwork.roomId, text: text, assigneeIds: assignees.map { $0.chatworkId}, limitType: .date, deadline: deadline)
            let chatworkClient = ChatworkClient(config: config.chatwork)
            chatworkClient.send(request) { taskResponse in
                let request = CreateReviewRequestRequest(pullRequestId: pullRequest.number, reviewers: assignees.map { $0.githubLogin })
                let githubClient = GithubClient(config: config.github)
                githubClient.send(request) { pullRequest in
                    completionHandler()
                }
            }
        }
    }
}