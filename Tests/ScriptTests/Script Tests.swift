import XCTest
import Script

final class ScriptCoreTests: XCTestCase {

  /// Verify `reduce` chunks input by splitAt delimiter (and handles non-string output)
  func testReduceInoutChunked() async throws {
    let result = CF.Result<CF.Ints>()  // reference type
    try runInScript {
      let sep: Character = ";"

      // inout, here using class
      try await echo(
        "1", "2\n3", "4", "not",
        separator: "\(sep)", terminator: "")
        | reduce(inputSeparator: sep, into: result) { $0.add(.make($1)) }
      XCTAssertEqual(CF.Ints.exp1234e, result.result, "Reduce (inside)")
    }
    XCTAssertEqual(CF.Ints.exp1234e, result.result, "Reduce (outside)")
  }

  /// Verify `reduce` chunks input by splitAt delimiter (and handles non-string output)
  func testReduceOutputChunked() async throws {
    try runInScript {
      let sep: Character = ";"

      let array: [CF.Ints] =
        try await echo(
          "1", "2\n3", "4", "not",
          separator: "\(sep)", terminator: "")
        | reduce(inputSeparator: sep, []) { r, s in r + [CF.Ints.make(s)] }
      XCTAssertEqual(CF.Ints.exp1234e, array, "Reduce (arrays)")
    }
  }

  /// Verify `map` chunks input by splitAt delimiter
  func testMapChunked() async throws {
    let expect = CF.Ints.exp1234e.map { $0.double() }.joined(separator: "\n")
    try runInScript {
      let sep: Character = ";"
      let result = try await outputOf {
        try await echo(
          "1", "2\n3", "4", "not",
          separator: "\(sep)", terminator: "")
          | map(inputSeparator: sep) { CF.Ints.make($0).double() }
      }
      XCTAssertEqual(expect, result, "Map")
    }
  }

  /// Verify `compactMap` chunks input by splitAt delimiter
  func testCompactMapChunked() async throws {
    let all: [CF.Ints] = [.i(1), .pair(2, 3), .i(4), .err("not")]
    let evens = all.compactMap { $0.anyEven() }.joined(separator: "\n")
    try runInScript {
      let sep: Character = ";"
      let result = try await outputOf {
        try await echo(
          "1", "2\n3", "4", "not",
          separator: "\(sep)", terminator: "")
          | compactMap(inputSeparator: sep) { CF.Ints.make($0).anyEven() }
      }
      XCTAssertEqual(evens, result, "Map")
    }
  }
  
  /// Verify `outputOf` applies explicit separator
  func testOutputSeparator() async throws {
    try runInScript {
      let result = try await outputOf(outputSeparator: "|") {
        try await echo("1", "2", "3", terminator: "")
        | map(inputSeparator: " ") { $0 }
      }
      XCTAssertEqual("1|2|3", result, "outputOf")
    }

    // Urk: echo newline dropped
    try runInScript {
      let result = try await outputOf(outputSeparator: "|") {
        try await echo("1", "2", "3")
        | map(inputSeparator: " ") { $0 }
      }
      // expecting `|3\n`, not `|3|`?
      let correct = "1|2|3\n|"
      let actual = "1|2|3|"
      XCTAssertEqual(actual, result, "outputOf-actual")
      XCTAssertEqual(correct, result, "outputOf-correct")
    }

    // Urk: lose initial value when map has output separator??
    try runInScript {
      let result = try await outputOf(outputSeparator: "|") {
        try await echo("1", "2", "3")
        // when map has output separator, first item dropped?
        | map(inputSeparator: " ", outputSeparator: "?") { $0 }
      }
      let correct = "1?2?3\n?`"
      let actual = "2?3|?"
      XCTAssertEqual(actual, result, "outputOf-actual")
      XCTAssertEqual(correct, result, "outputOf-correct")
    }
  }
  
  func testEcho() async throws {
    let tests: [(exp: String, term: String, items: [String])] = [
      ("1", "", ["1"]),
      ("1|", "|", ["1"]),
      ("1 2", "", ["1", "2"]),
      ("1 2|", "|", ["1", "2"]),
    ]
    for (exp, term, items) in tests {
      try runInScript {
        let result = try await outputOf() {
          if 1 == items.count {
            try await echo(items[0], terminator: term)
          } else {
            try await echo(items[0], items[1], terminator: term)
          }
        }
        XCTAssertEqual(exp, result, "echo term=\(term), items=\(items)")
      }
    }
  }

  func testMapOutputSeparator() async throws {
    try runInScript {
      let result = try await outputOf(inputSeparator: " ", outputSeparator: "|") {
        try await echo("1", "2", "3")
        | map(inputSeparator: " ", outputSeparator: "Once") { $0 }
      }
      XCTAssertEqual("1|2|3Once", result, "outputOf")
    }
  }

  /// Verify `outputOf` applies explicit separator
  func testOutput() async throws {
    try runInScript {
      let result = try await outputOf(outputSeparator: "?") {
        try await echo("1", "2", "3", separator: ";", terminator: "|")
      }
      XCTAssertEqual("1;2;3|", result, "outputOf")
    }
  }

  func runInScript(
    _ op: @escaping () async throws -> Void,
    caller: StaticString = #function,
    callerLine: UInt = #line
  ) throws {
    let e = expectation(description: "\(caller):\(callerLine)")
    defer { wait(for: [e], timeout: 2) }
    try RunInScriptProxy(op, e).run()
  }

  private struct RunInScriptProxy: Script, Codable {
    typealias Op = () async throws -> Void
    var op: Op?
    var e: XCTestExpectation?
    init(_ op: @escaping Op, _ e: XCTestExpectation) {
      self.op = op
      self.e = e
    }
    func run() async throws {
      defer { e?.fulfill() }
      try await op?()
    }
    // Codable
    init() {}
    var i = 0
    private enum CodingKeys: String, CodingKey {
      case i
    }
  }

  private typealias CF = ChunkFixtures
  private enum ChunkFixtures {
    class Result<T> {
      var result = [T]()
      func add(_ next: T) {
        result.append(next)
      }
    }
    enum Ints: Codable, Equatable {
      case i(Int), pair(Int, Int), err(String)

      static let exp1234e: [Ints] = [.i(1), .pair(2, 3), .i(4), .err("not")]

      static func make(_ s: String) -> Ints {
        let nums = s.split(separator: "\n")
        switch nums.count {
        case 1:
          if let i = Int(nums[0]) {
            return .i(i)
          }
          return err(s)
        case 2: return .pair(Int(nums[0]) ?? -1, Int(nums[1]) ?? -2)
        default: return .err(s)
        }
      }

      func double() -> String {
        switch self {
        case .i(let n): return "\(2*n)"
        case .pair(let i, let j): return "\(2*i)\n\(2*j)"
        case .err(let s): return "\(s)\(s)"
        }
      }

      func anyEven() -> String? {
        func anyEvens(_ i: Int...) -> Bool {
          nil != i.first { 0 == $0 % 2 }
        }
        switch self {
        case .i(let n): return anyEvens(n) ? "\(n)" : nil
        case .pair(let i, let j): return anyEvens(i, j) ? "\(i)\n\(j)" : nil
        case .err: return nil
        }
      }
    }
  }
}
