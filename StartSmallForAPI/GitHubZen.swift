import Foundation



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
        via api: GitHubAPI,
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
        api.call(with: input) { output in
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
