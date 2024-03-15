import Shwift

/**
 By default, shell output is processed as a list of lines
 */

public func map(
  inputSeparator: Character = "\n",
  outputSeparator: String = "\n",
  transform: @Sendable @escaping (String) async throws -> String
) -> Shell.PipableCommand<Void> {
  compactMap(inputSeparator: inputSeparator, outputSeparator: outputSeparator, transform: transform)
}

public func compactMap(
  inputSeparator: Character = "\n",
  outputSeparator: String = "\n",
  transform: @Sendable @escaping (String) async throws -> String?
) -> Shell.PipableCommand<Void>
{
  Shell.PipableCommand {
    try await Shell.invoke { shell, invocation in
      try await invocation.builtin { channel in
        for try await line in channel.input.chunks(inputSeparator).compactMap(transform) {
          try await channel.output.withTextOutputStream { stream in
            print(line, terminator: outputSeparator, to: &stream)
          }
        }
      }
    }
  }
}

public func reduce<T>(
  inputSeparator: Character = "\n",
  into initialResult: T,
  _ updateAccumulatingResult: @escaping (inout T, String) async throws -> Void
) -> Shell.PipableCommand<T> {
  Shell.PipableCommand {
    try await Shell.invoke { _, invocation in
      try await invocation.builtin { channel in
        try await channel.input
          .chunks(inputSeparator).reduce(into: initialResult, updateAccumulatingResult)
      }
    }
  }
}

public func reduce<T>(
  inputSeparator: Character = "\n",
  _ initialResult: T,
  _ nextPartialResult: @escaping (T, String) async throws -> T
) -> Shell.PipableCommand<T> {
  Shell.PipableCommand {
    try await Shell.invoke { _, invocation in
      try await invocation.builtin { channel in
        try await channel.input.chunks(inputSeparator)
          .reduce(initialResult, nextPartialResult)
      }
    }
  }
}
