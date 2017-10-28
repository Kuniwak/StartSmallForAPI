class ContextualWebAPI {
    private let inputTransformer: (Input) -> Input
    private let outputTransformer: (Output) -> Output


    init(
        transformingInputBy inputTransformer: @escaping (Input) -> Input,
        transformingOutputBy outputTransformer: @escaping (Output) -> Output
    ) {
        self.inputTransformer = inputTransformer
        self.outputTransformer = outputTransformer
    }


    func call(with input: Input) {
        self.call(with: input) { _ in }
    }


    func call(with input: Input, _ block: @escaping (Output) -> Void) {
        let newInput = self.inputTransformer(input)

        WebAPI.call(with: newInput) { output in
            let newOutput = self.outputTransformer(output)
            block(newOutput)
        }
    }
}
