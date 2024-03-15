import Shwift

/**
 By default, shell output is processed as a list of lines
 */

public func map(
  splitAt char: Character = "\n",
  transform: @Sendable @escaping (String) async throws -> String
) -> Shell.PipableCommand<Void> {
  compactMap(splitAt: char, transform: transform)
}

public func compactMap(
  splitAt char: Character = "\n",
  transform: @Sendable @escaping (String) async throws -> String?
) -> Shell.PipableCommand<Void>
{
  Shell.PipableCommand {
    try await Shell.invoke { shell, invocation in
      try await invocation.builtin { channel in
        for try await line in channel.input.chunks(char).compactMap(transform) {
          try await channel.output.withTextOutputStream { stream in
            print(line, to: &stream)
          }
        }
      }
    }
  }
}

public func reduce<T>(
  splitAt: Character = "\n",
  into initialResult: T,
  _ updateAccumulatingResult: @escaping (inout T, String) async throws -> Void
) -> Shell.PipableCommand<T> {
  Shell.PipableCommand {
    try await Shell.invoke { _, invocation in
      try await invocation.builtin { channel in
        try await channel.input
          .chunks(splitAt).reduce(into: initialResult, updateAccumulatingResult)
      }
    }
  }
}

public func reduce<T>(
  splitAt: Character = "\n",
  _ initialResult: T,
  _ nextPartialResult: @escaping (T, String) async throws -> T
) -> Shell.PipableCommand<T> {
  Shell.PipableCommand {
    try await Shell.invoke { _, invocation in
      try await invocation.builtin { channel in
        try await channel.input.chunks(splitAt)
          .reduce(initialResult, nextPartialResult)
      }
    }
  }
}
