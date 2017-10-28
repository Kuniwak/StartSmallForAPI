@testable import StartSmallForAPI



class AuthorizedGitHubAPIStub: AuthorizedGitHubAPI {
    private let output: Output


    init(willReturn output: Output) {
        self.output = output
    }


    func call(with input: Input) {}


    func call(with input: Input, _ block: @escaping (Output) -> Void) {
        block(output)
    }
}



class AuthorizedGitHubAPISpy: AuthorizedGitHubAPI {
    private let stub: AuthorizedGitHubAPI
    private(set) var callArgs = [CallArgs]()
    enum CallArgs {
        case call1(with: Input)
        case call2(with: Input, (Output) -> Void)
    }


    init(inheriting stub: AuthorizedGitHubAPI) {
        self.stub = stub
    }


    func call(with input: Input) {
        self.stub.call(with: input)
        self.callArgs.append(.call1(with: input))
    }


    func call(with input: Input, _ block: @escaping (Output) -> Void) {
        self.stub.call(with: input, block)
        self.callArgs.append(.call2(with: input, block))
    }
}