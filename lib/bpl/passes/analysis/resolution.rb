# typed: true
module Bpl
  class Resolution < Pass

    switch "--resolution", "Resolve types and identifiers."

    def run! program

      program.each do |elem|
        elem.bindings.clear if elem.respond_to?(:bindings)
        elem.unbind if elem.respond_to?(:unbind)
      end

      program.each do |elem|
        next unless elem.respond_to?(:bind)

        resolver = elem.each_ancestor.find do |scope|
          scope.respond_to?(:resolve) && scope.resolve(elem)
        end

        if resolver
          elem.bind(resolver.resolve(elem))
        else
          kind = case elem
            when StorageIdentifier then "constant/variable"
            when ProcedureIdentifier then "procedure"
            when FunctionIdentifier then "function"
            when Identifier then "identifier"
            when CustomType then "type"
            when ImplementationDeclaration then "implementation"
            end
          warn ("could not resolve #{kind} #{elem.name}")

        end
      end

      false
    end

  end
end
