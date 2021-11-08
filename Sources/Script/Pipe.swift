
import Shell

@discardableResult
public func |<T> (
  source: Shell._Invocation<Void>,
  destination: Shell._Invocation<T>
) async throws -> T {
  try await Shell.withCurrent { shell in
    try await shell.pipe(
      .output,
      of: { shell in
      try await Shell.withSubshell(shell) { try await source.body() }
      },
      to: { shell in
        try await Shell.withSubshell(shell) { try await destination.body() }
      }).destination
  }
}

@discardableResult
@_disfavoredOverload
public func |<T> (
  source: Shell._Invocation<Void>,
  destination: Shell._Invocation<T>
) async throws -> Shell._Invocation<T> {
  Shell._Invocation { _ in
    try await source | destination
  }
}

extension Shell {
  
  /**
   We use this type to work around https://bugs.swift.org/browse/SR-14517
   
   Instead of having `|` take async autoclosure arguments, we have it take this type, and provide disfavored overloads which create `_Invocation` for interesting APIs. Some API doesn't really make sense outside of a pipe expression, and we only provide the `_Invocation` variant for such API.
   */
  public struct _Invocation<T> {
    init(body: @escaping () async throws -> T) {
      self.body = body
    }
    init(body: @escaping (Shell) async throws -> T) {
      self.body = { try await Shell.withCurrent(operation: body) }
    }
    let body: () async throws -> T
  }
  
}
