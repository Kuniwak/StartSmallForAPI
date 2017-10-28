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



protocol GitHubAPI {
    func call(with input: Input)
    func call(with input: Input, _ block: @escaping (Output) -> Void)
}



protocol AuthorizedGitHubAPI: GitHubAPI {}



class AnonymouseGitHubAPI: GitHubAPI {
    func call(with input: Input) {
        WebAPI.call(with: input)
    }


    func call(with input: Input, _ block: @escaping (Output) -> Void) {
        WebAPI.call(with: input, block)
    }
}



class HeaderAuthorizationGitHubAPI: AuthorizedGitHubAPI {
    private let contextualWebAPI: ContextualWebAPI


    init(authorizedBy token: GitHubAPIToken) {
        self.contextualWebAPI = ContextualWebAPI(
            transformingInputBy: { input in
                var newHeaders = input.headers
                newHeaders["Authorization"] = "token \(token.text)"

                var newInput = input
                newInput.headers = newHeaders

                return newInput
            },
            transformingOutputBy: { $0 }
        )
    }


    func call(with input: Input) {
        self.contextualWebAPI.call(with: input)
    }


    func call(with input: Input, _ block: @escaping (Output) -> Void) {
        self.contextualWebAPI.call(with: input, block)
    }
}
