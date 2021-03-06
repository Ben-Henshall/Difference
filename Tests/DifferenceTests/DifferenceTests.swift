//
//  DifferenceTests.swift
//  Difference
//
//  Created by Krzysztof Zablocki on 18.10.2017
//  Copyright © 2017 Krzysztof Zablocki. All rights reserved.
//

import Foundation
import XCTest
import Difference

fileprivate struct Person: Equatable {
    let name: String
    let age: Int
    let address: Address
    let pet: Pet?
    let petAges: [String: Int]?
    let favoriteFoods: Set<String>?

    init(
        name: String = "Krzysztof",
        age: Int = 29,
        address: Address = .init(),
        pet: Pet? = .init(),
        petAges: [String: Int]? = nil,
        favoriteFoods: Set<String>? = nil
    ) {
        self.name = name
        self.age = age
        self.address = address
        self.pet = pet
        self.petAges = petAges
        self.favoriteFoods = favoriteFoods
    }

    struct Address: Equatable {
        let street: String
        let postCode: String
        let counter: ComplexCounter

        init(
            street: String = "Times Square",
            postCode: String = "00-1000",
            counter: ComplexCounter = .init()
        ) {
            self.street = street
            self.postCode = postCode
            self.counter = counter
        }

        struct ComplexCounter: Equatable {
            let counter: Int

            init(counter: Int = 2) {
                self.counter = counter
            }
        }
    }

    struct Pet: Equatable {
        let name: String

        init(name: String = "Fluffy") {
            self.name = name
        }
    }
}

private enum State {
    case loaded([Int], String)
    case anotherLoaded([Int], String)
    case loadedWithDiffArguments(Int)
    case loadedWithNoArguments
}

class DifferenceTests: XCTestCase {
    func testCanFindRootPrimitiveDifference() {
        let results = diff(2, 3)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first, "Received: 3\nExpected: 2\n")
    }

    fileprivate let truth = Person()

    func testCanFindPrimitiveDifference() {
        let stub = Person(age: 30)
        let results = diff(truth, stub)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first, "age:\n|\tReceived: 30\n|\tExpected: 29\n")

    }

    func testCanFindMultipleDifference() {
        let stub = Person(name: "Adam", age: 30)
        let results = diff(truth, stub)

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results.first, "name:\n|\tReceived: Adam\n|\tExpected: Krzysztof\n")
        XCTAssertEqual(results.last, "age:\n|\tReceived: 30\n|\tExpected: 29\n")
    }

    func testCanFindComplexDifference() {
        let stub = Person(address: Person.Address(street: "2nd Street", counter: .init(counter: 1)))
        let results = diff(truth, stub)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first, "address:\n|\tcounter:\n|\t|\tcounter:\n|\t|\t|\tReceived: 1\n|\t|\t|\tExpected: 2\n|\tstreet:\n|\t|\tReceived: 2nd Street\n|\t|\tExpected: Times Square\n")

    }

    func testCanGiveDescriptionForOptionalOnLeftSide() {
        let truth = Person(pet: nil)
        let stub = Person()
        let results = diff(truth, stub)

        XCTAssertEqual(results.count, 1)
    }

    func testCanGiveDescriptionForOptionalOnRightSide() {
        let truth = Person()
        let stub = Person(pet: nil)
        let results = diff(truth, stub)

        XCTAssertEqual(results.count, 1)
    }

    // MARK: Collections

    func test_canFindCollectionCountDifference() {
        let results = diff([1], [1, 3])

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first, "Different count:\n|\tReceived: (2) [1, 3]\n|\tExpected: (1) [1]\n")
    }

    func test_canFindCollectionCountDifference_complex() {
        let truth = State.loaded([1, 2], "truthString")
        let stub = State.loaded([], "stubString")
        let results = diff(truth, stub)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first, "Enum loaded:\n|\t.0:\n|\t|\tDifferent count:\n|\t|\t|\tReceived: (0) []\n|\t|\t|\tExpected: (2) [1, 2]\n|\t.1:\n|\t|\tReceived: stubString\n|\t|\tExpected: truthString\n")
    }

    func test_labelsArrayElementsInDiff() {
        let truth = [Person(), Person(name: "John")]
        let stub = [Person(name: "John"), Person()]
        let results = diff(truth, stub)

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results.first, "Collection[0]:\n|\tname:\n|\t|\tReceived: John\n|\t|\tExpected: Krzysztof\n")
        XCTAssertEqual(results.last, "Collection[1]:\n|\tname:\n|\t|\tReceived: Krzysztof\n|\t|\tExpected: John\n")
    }

    // MARK: Enums

    func test_canFindEnumCaseDifferenceWhenAssociatedValuesAreIdentical() {
        let truth = State.loaded([0], "CommonString")
        let stub = State.anotherLoaded([0], "CommonString")
        let results = diff(truth, stub)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first, "Received: anotherLoaded\nExpected: loaded\n")
    }

    func test_canFindEnumCaseDifferenceWhenLessArguments() {
        let truth = State.loaded([0], "CommonString")
        let stub = State.loadedWithDiffArguments(1)
        let results = diff(truth, stub)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first, "Received: loadedWithDiffArguments\nExpected: loaded\n")
    }

    // MARK: Dictionaries

    func test_canFindDictionaryCountDifference() {
        let truth = Person(petAges: ["Henny": 4])
        let stub = Person(petAges: [:])
        let results = diff(truth, stub)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first, "petAges:\n|\tDifferent count:\n|\t|\tReceived: (0) [:]\n|\t|\tExpected: (1) [\"Henny\": 4]\n")
    }

    func test_canFindOptionalDifferenceBetweenSomeAndNone() {
        let truth = Person(petAges: ["Henny": 4])
        let stub = Person(petAges: nil)
        let results = diff(truth, stub)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first, "petAges:\n|\tReceived: nil\n|\tExpected: Optional([\"Henny\": 4])\n")
    }

    func test_canFindDictionaryDifference() {
        let truth = Person(petAges: ["Henny": 4, "Jethro": 6])
        let stub = Person(petAges: ["Henny": 1, "Jethro": 2])
        let results = diff(truth, stub)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first, "petAges:\n|\tKey Henny:\n|\t|\tReceived: 1\n|\t|\tExpected: 4\n|\tKey Jethro:\n|\t|\tReceived: 2\n|\t|\tExpected: 6\n")
    }

    // MARK: Sets

    func test_canFindSetCountDifference() {
        let truth = Person(favoriteFoods: [])
        let stub = Person(favoriteFoods: ["Oysters"])
        let results = diff(truth, stub)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first, "favoriteFoods:\n|\tDifferent count:\n|\t|\tReceived: (1) [\"Oysters\"]\n|\t|\tExpected: (0) []\n")
    }

    func test_canFindOptionalSetDifferenceBetweenSomeAndNone() {
        let truth = Person(favoriteFoods: ["Oysters"])
        let stub = Person(favoriteFoods: nil)
        let results = diff(truth, stub)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first, "favoriteFoods:\n|\tReceived: nil\n|\tExpected: Optional(Set([\"Oysters\"]))\n")
    }

    func test_canFindSetDifference() {
        let truth = Person(favoriteFoods: ["Sushi", "Pizza"])
        let stub = Person(favoriteFoods: ["Oysters", "Crab"])
        let results = diff(truth, stub)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first, "favoriteFoods:\n|\tMissing: Pizza\n|\tMissing: Sushi\n")
    }
}

extension DifferenceTests {
    static var allTests = [
        ("testCanFindRootPrimitiveDifference", testCanFindRootPrimitiveDifference),
        ("testCanFindPrimitiveDifference", testCanFindPrimitiveDifference),
        ("testCanFindMultipleDifference", testCanFindMultipleDifference),
        ("testCanFindComplexDifference", testCanFindComplexDifference),
        ("testCanGiveDescriptionForOptionalOnLeftSide", testCanGiveDescriptionForOptionalOnLeftSide),
        ("testCanGiveDescriptionForOptionalOnRightSide", testCanGiveDescriptionForOptionalOnRightSide),
        ("test_canFindCollectionCountDifference", test_canFindCollectionCountDifference),
        ("test_canFindCollectionCountDifference_complex", test_canFindCollectionCountDifference_complex),
        ("test_labelsArrayElementsInDiff", test_labelsArrayElementsInDiff),
        ("test_canFindEnumCaseDifferenceWhenAssociatedValuesAreIdentical", test_canFindEnumCaseDifferenceWhenAssociatedValuesAreIdentical),
        ("test_canFindEnumCaseDifferenceWhenLessArguments", test_canFindEnumCaseDifferenceWhenLessArguments),
        ("test_canFindDictionaryCountDifference", test_canFindDictionaryCountDifference),
        ("test_canFindOptionalDifferenceBetweenSomeAndNone", test_canFindOptionalDifferenceBetweenSomeAndNone),
        ("test_canFindDictionaryDifference", test_canFindDictionaryDifference),
        ("test_canFindSetCountDifference", test_canFindSetCountDifference),
        ("test_canFindOptionalSetDifferenceBetweenSomeAndNone", test_canFindOptionalSetDifferenceBetweenSomeAndNone),
        ("test_canFindSetDifference", test_canFindSetDifference)
    ]
}
