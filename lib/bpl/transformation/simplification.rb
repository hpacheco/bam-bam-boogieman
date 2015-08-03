module Bpl

  module AST
    class Node
      def simplify
      end
    end

    class AxiomDeclaration
      def simplify
        if expression.is_a?(BooleanLiteral) && expression.value == true
          yield({
            description: "removing trivial axiom",
            action: Proc.new do
              remove
            end
          })
        end
      end
    end

    class VariableDeclaration
      def simplify
        if bindings.all? do |b|
          b.parent.is_a?(HavocStatement) || b.parent.is_a?(ModifiesClause)
        end then
          yield({
            description: "removing unused variable",
            action: Proc.new do
              bindings.each do |b|
                if b.parent.identifiers.count == 1
                  b.parent.remove
                else
                  b.remove
                end
              end
              remove
            end
          })
        end
      end
    end

    class ProcedureDeclaration
      def simplify
        if modifies.empty? && returns.empty? && body &&
           !attributes[:has_assertion]
          yield({
            description: "simplifying trivial procedure",
            action: Proc.new do
              replace_children(:body,nil)
            end
          })
        end
      end
    end

    class Body
      def simplify
        blocks.each do |bb|
          if bb.successors.count == 2 &&
             bb.statements.last.is_a?(GotoStatement) &&
             bb.statements.last.identifiers.count == 2
          then
            b1, b2 = bb.successors.to_a
            if b1 != b2 &&
               b1.successors.count == 1 &&
               b1.successors == b2.successors &&
               b1.statements.count == 1 &&
               b1.statements.last.is_a?(GotoStatement) &&
               b2.statements.count == 1 &&
               b2.statements.last.is_a?(GotoStatement)
            then
              yield({
                description: "cutting unnecessary branch",
                elems: [bb,b1,b2],
                action: Proc.new do
                  bb.statements.last.replace_with(b1.statements.last.copy)
                  b1.remove
                  b2.remove
                end
              })
            end
          end
        end
      end
    end

    class Block
      def simplify
        if statements.count == 1 &&
           statements.first.is_a?(GotoStatement) &&
           statements.first.identifiers.count == 1 &&
           predecessors.count == 1 &&
           predecessors.first.statements.last.is_a?(GotoStatement) &&
           predecessors.first.statements.last.identifiers.count == 1
          yield({
            description: "removing trivial block",
            action: Proc.new do
              predecessors.first.statements.last.replace_with(statements.last)
              remove
            end
          })
        end
      end
    end

    class AssertStatement
      def simplify
        if expression.is_a?(BooleanLiteral) && expression.value == true
          yield({
            description: "removing trivial assert",
            action: Proc.new do
              remove
            end
          })
        end
      end
    end

    class AssumeStatement
      def simplify
        if expression.is_a?(BooleanLiteral) && expression.value == true
          yield({
            description: "removing trivial assume",
            action: Proc.new do
              remove
            end
          })
        end
      end
    end

    class CallStatement
      def simplify
        decl = procedure.declaration
        if decl.modifies.empty? &&
           decl.returns.empty? &&
           !decl.attributes[:has_assertion]
#
          yield({
            description: "removing trivial call",
            action: Proc.new do
              remove
            end
          })
        end
      end
    end

  end

  module Transformation
    class Simplification < Bpl::Pass

      def self.description
        <<-eos
          Various code simplifications.
          * remove trivial assume (true) statements
        eos
      end

      depends :modifies_correction
      depends :resolution, :cfg_construction, :assertion_localization

      def run! program
        updated = false
        program.each do |elem|
          elem.simplify do |x|
            info "SIMPLIFICATION * #{x[:description]}"
            (x[:elems]||[elem]).each {|e| info Printing.indent(e.to_s).indent}
            info
            x[:action].call()
            updated = true
          end
        end
        :simplification if updated
      end

    end
  end
end
