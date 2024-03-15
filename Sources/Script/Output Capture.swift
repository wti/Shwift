public func outputOf(
  inputSeparator: Character = "\n",
  outputSeparator: String = "\n",
  _ operation: @escaping () async throws -> Void
) async throws -> String {
  let lines = try await Shell.PipableCommand(operation) 
  | reduce(inputSeparator: inputSeparator, into: []) { $0.append($1) }
  return lines.joined(separator: outputSeparator)
}
