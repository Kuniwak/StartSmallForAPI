import XCTest
@testable import StartSmallForAPI


class StartSmallForAPITests: XCTestCase {
    func testRequest() {
        let input: Input = (
            url: URL(string: "https://api.github.com/zen")!,
            queries: [],
            headers: [:],
            methodAndPayload: .get
        )
        WebAPI.call(with: input)
    }


    func testResponse() {
        let text = "this is a response text"
        let response: Response = (
            statusCode: .ok,
            headers: [:],
            payload: text.data(using: .utf8)!
        )

        let errorOrZen = GitHubZen.from(response: response)
        switch errorOrZen {
        case let .left(error):
            XCTFail("\(error)")

        case let .right(zen):
            XCTAssertEqual(zen.text, text)
        }
    }


    func testRequestAndResponse() {
        let expectation = self.expectation(description: "API")

        let input: Input = (
            url: URL(string: "https://api.github.com/zen")!,
            queries: [],
            headers: [:],
            methodAndPayload: .get
        )

        WebAPI.call(with: input) { output in
            switch output {
            case let .noResponse(connectionError):
                XCTFail("\(connectionError)")

            case let .hasResponse(response):
                let errorOrZen = GitHubZen.from(response: response)
                XCTAssertNotNil(errorOrZen.right)
            }

            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 10)
    }
}
