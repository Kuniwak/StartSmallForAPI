import Foundation



struct GitHubUser: Codable {
    let id: Int
    let login: String


    static func from(response: Response) -> Either<TransformError, GitHubUser> {
        switch response.statusCode {
        case .ok:
            do {
                let jsonDecoder = JSONDecoder()
                let user = try jsonDecoder.decode(GitHubUser.self, from: response.payload)
                return .right(user)
            }
            catch {
                return .left(.malformedData(debugInfo: "\(error)"))
            }

        default:
            return .left(.unexpectedStatusCode(debugInfo: "\(response.statusCode)"))
        }
    }


    static func fetch(
        byLogin login: String,
        via api: GitHubAPI,
        _ block: @escaping (Either<Either<ConnectionError, TransformError>, GitHubUser>) -> Void
    ) {
        let urlString = "https://api.github.com/users"
        guard let url = URL(string: urlString)?.appendingPathComponent(login) else {
            block(.left(.left(.malformedURL(debugInfo: "\(urlString)/\(login)"))))
            return
        }

        let input: Input = (
            url: url,
            queries: [],
            headers: [:],
            methodAndPayload: .get
        )

        api.call(with: input) { output in
            switch output {
            case let .noResponse(connectionError):
                block(.left(.left(connectionError)))

            case let .hasResponse(response):
                let errorOrUser = GitHubUser.from(response: response)

                switch errorOrUser {
                case let .left(transformError):
                    block(.left(.right(transformError)))

                case let .right(user):
                    block(.right(user))
                }
            }
        }
    }


    static func fetch(
        via api: AuthorizedGitHubAPI,
        _ block: @escaping (Either<Either<ConnectionError, TransformError>, GitHubUser>) -> Void
    ) {
        let urlString = "https://api.github.com/user"
        guard let url = URL(string: urlString) else {
            block(.left(.left(.malformedURL(debugInfo: urlString))))
            return
        }

        let input: Input = (
            url: url,
            queries: [],
            headers: [:],
            methodAndPayload: .get
        )

        api.call(with: input) { output in
            switch output {
            case let .noResponse(connectionError):
                block(.left(.left(connectionError)))

            case let .hasResponse(response):
                let errorOrUser = GitHubUser.from(response: response)

                switch errorOrUser {
                case let .left(transformError):
                    block(.left(.right(transformError)))

                case let .right(user):
                    block(.right(user))
                }
            }
        }
    }


    enum TransformError {
        case malformedUsername(debugInfo: String)
        case malformedData(debugInfo: String)
        case unexpectedStatusCode(debugInfo: String)
    }
}
