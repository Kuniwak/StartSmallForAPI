import Foundation


enum Either<Left, Right> {
    case left(Left)
    case right(Right)

    var left: Left? {
        switch self {
        case let .left(x):
            return x

        case .right:
            return nil
        }
    }

    var right: Right? {
        switch self {
        case .left:
            return nil

        case let .right(x):
            return x
        }
    }
}



struct GitHubZen {
    let text: String


    static func from(response: Response) -> Either<TransformError, GitHubZen> {
        switch response.statusCode {
        case .ok:
            guard let string = String(data: response.payload, encoding: .utf8) else {
                return .left(.malformedData(debugInfo: "not UTF-8 string"))
            }

            return .right(GitHubZen(text: string))

        default:
            return .left(.unexpectedStatusCode(
                debugInfo: "\(response.statusCode)")
            )
        }
    }


    static func fetch(
        _ block: @escaping (Either<Either<ConnectionError, TransformError>, GitHubZen>) -> Void
    ) {
        let urlString = "https://api.github.com/zen"
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
        WebAPI.call(with: input) { output in
            switch output {
            case let .noResponse(connectionError):
                block(.left(.left(connectionError)))

            case let .hasResponse(response):
                let errorOrZen = GitHubZen.from(response: response)

                switch errorOrZen {
                case let .left(error):
                    block(.left(.right(error)))

                case let .right(zen):
                    block(.right(zen))
                }
            }
        }
    }


    enum TransformError {
        case malformedData(debugInfo: String)
        case unexpectedStatusCode(debugInfo: String)
    }
}



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

        WebAPI.call(with: input) { output in
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
