public func reduceSegments<T>(
  separatedBy delimiter: Character,
  into initialResult: T,
  _ updateAccumulatingResult: @escaping (inout T, String) async throws -> Void
) -> Shell.PipableCommand<T> {
  Shell.PipableCommand {
    try await Shell.invoke { _, invocation in
      try await invocation.builtin { channel in
        try await channel.input.segments(separatedBy: delimiter)
          .reduce(into: initialResult, updateAccumulatingResult)
      }
    }
  }
}

