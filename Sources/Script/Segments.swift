import Shwift

/// Make PipableCommand running over ``AsyncSequence`` ``Builtin/Input/Segments``.
public func withSegments<T>(
  separatedBy delimiter: String = "\n",
  _ run: @escaping (Builtin.Input.Segments) async throws -> T
) -> Shell.PipableCommand<T> {
  Shell.PipableCommand {
    try await Shell.invoke { _, invocation in
      try await invocation.builtin { channel in
        try await run(channel.input.segments(separatedBy: delimiter))
      }
    }
  }
}

/// Make PipableCommand reducing segmented input to some value (ending the pipe)
public func reduceSegments<T>(
  separatedBy delimiter: String,
  into initialResult: T,
  _ updateAccumulatingResult: @escaping (inout T, String) async throws -> Void
) -> Shell.PipableCommand<T> {
  withSegments(separatedBy: delimiter) {
    try await $0.reduce(into: initialResult, updateAccumulatingResult)
  }
}

