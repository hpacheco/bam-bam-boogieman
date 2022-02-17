# typed: false
require_relative 'node'

module Bpl
  module AST
    class Program < Node
      include Scope

      children :declarations
      attr_accessor :source_file

      def show
        @declarations.map{|d| yield d} * "\n" + "\n"
      end

      def global_variables
        each_child.select{|d| d.is_a?(VariableDeclaration)}
      end

      def fresh_var(type, prefix: pre)
        taken = global_variables.map{|d| d.names}.flatten
        name = pre unless taken.include?(pre)
        name ||= (0..Float::INFINITY).each do |i|
          break "#{pre}_#{i}" unless taken.include?("#{pre}_#{i}")
        end
        self << decl = bpl("var #{name}: #{type};")
        return StorageIdentifier.new(name: name, declaration: decl)
      end

    end
  end
end
