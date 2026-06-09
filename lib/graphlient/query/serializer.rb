require_relative 'directive'
require_relative 'serializer/scalars'
require_relative 'serializer/arguments'
require_relative 'serializer/evaluator'
require_relative 'serializer/fragments'
require_relative 'serializer/directives'

module Graphlient
  class Query
    # Builds a GraphQL query string from a DSL block.
    # Composed from focused concern modules; Query is a thin public wrapper.
    class Serializer
      include Scalars
      include Arguments
      include Evaluator
      include Fragments
      include Directives

      ROOT_NODES = %w[query mutation subscription].freeze

      ROOT_NODES.each do |root_node|
        define_method(root_node) do |*args, &block|
          @variables = args.first || {}
          append_node(root_node, args, arg_processor: variable_processor, &block)
        end
      end

      attr_accessor :query_str

      def initialize(&block)
        @indents   = 0
        @query_str = ''
        @variables = {}
        @fragments = {}
        evaluate(&block) if block
      end

      # Full output: main query string + any inline fragment definitions.
      def to_s
        parts = [query_str.strip]
        parts.concat(@fragments.values) unless @fragments.empty?
        parts.join("\n\n")
      end

      # Named fragment spread: ...FragmentName [@directive ...]
      #   spread :InvoiceFields
      #   spread :InvoiceFields, _skip(if: :x)   # → ...InvoiceFields @skip(if: $x)
      def spread(fragment_name, *args)
        directives = args.select { |a| a.is_a?(Directive) }
        @query_str << "\n#{indent}...#{fragment_name}"
        directives.each { |d| @query_str << " #{d}" }
        @query_str << "\n#{indent}"
      end

      # Inline fragment: ... on Type [@directive ...] { fields }
      #   on(:PaidInvoice) { amount_paid }
      #   on(:DraftInvoice, _skip(if: :skip)) { draft_id }
      def on(type, *args, &block)
        directives = args.select { |a| a.is_a?(Directive) }
        @query_str << "\n#{indent}... on #{type}"
        directives.each { |d| @query_str << " #{d}" }
        if block_given?
          @indents += 1
          @query_str << '{'
          evaluate(&block)
          @query_str << '}'
          @indents -= 1
        end
        @query_str << "\n#{indent}"
      end

      # Inline fragment definition — collected and appended after the main query.
      #   fragment(:InvoiceFields, on: :Invoice) { id; fee_in_cents }
      def fragment(name, on:, &block)
        body = self.class.new(&block).query_str.strip
        @fragments[name] = "fragment #{name} on #{on} {\n#{body}\n}"
      end

      def method_missing(method_name, *args, &block)
        if fragment?(method_name)
          append_node("...#{resolve_fragment_constant(method_name)}".to_sym, args, &block)
        elsif directive?(method_name)
          Directive.new(method_name, args.first || {})
        else
          append_node(method_name, args, &block)
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        super
      end

      private

      def indent
        '  ' * @indents
      end

      def append_node(node, args, arg_processor: nil, &block) # rubocop:disable Metrics/MethodLength
        regular = field_args(args)
        dirs    = directive_args(args)

        @query_str << "\n#{indent}#{node}"

        if (h = hash_arg(regular))
          @query_str << "(#{args_str(h, arg_processor: arg_processor)})"
        end

        dirs.each { |d| @query_str << " #{d}" }

        if block_given?
          @indents += 1
          @query_str << '{'
          evaluate(&block)
          @query_str << '}'
          @indents -= 1
        end

        @query_str << "\n#{indent}"
      end
    end
  end
end
