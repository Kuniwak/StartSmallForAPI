import XCTest
@testable import StartSmallForAPI


class GitHubAPITests: XCTestCase {
    func testZenFetch() {
        let expectation = self.expectation(description: "API")

        GitHubZen.fetch { errorOrZen in
            switch errorOrZen {
            case let .left(error):
                XCTFail("\(error)")

            case let .right(zen):
                XCTAssertNotNil(zen)
            }

            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 10)
    }


    func testZenFetchTwice() {
        let expectation = self.expectation(description: "API")

        GitHubZen.fetch { errorOrZen in
            switch errorOrZen {
            case let .left(error):
                XCTFail("\(error)")

            case .right(_):
                GitHubZen.fetch { errorOrZen in
                    switch errorOrZen {
                    case let .left(error):
                        XCTFail("\(error)")

                    case let .right(zen):
                        XCTAssertNotNil(zen)
                        expectation.fulfill()
                    }
                }
            }
        }

        self.waitForExpectations(timeout: 10)
    }


    func testUser() throws {
        let response: Response = (
            statusCode: .ok,
            headers: [:],
            payload: try JSONSerialization.data(withJSONObject: [
                "id": 1,
                "login": "octocat"
            ])
        )

        switch GitHubUser.from(response: response) {
        case let .left(error):
            XCTFail("\(error)")

        case let .right(user):
            XCTAssertEqual(user.id, 1)
            XCTAssertEqual(user.login, "octocat")
        }
    }


    func testUserFetch() {
        let expectation = self.expectation(description: "API")

        GitHubUser.fetch(byLogin: "Kuniwak") { errorOrUser in
            switch errorOrUser {
            case let .left(error):
                XCTFail("\(error)")

            case let .right(user):
                XCTAssertEqual(user.id, 1124024)
                XCTAssertEqual(user.login, "Kuniwak")
            }

            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 10)
    }
}
