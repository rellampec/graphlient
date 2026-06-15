module Graphlient
  class Query
    # Value object returned by `_directive_name(args)` in the DSL.
    #
    # Rather than writing directly to the query string (which would produce
    # the wrong position -- before the field name), _skip / _include etc.
    # return a Directive instance.  append_node / spread / on detect Directive
    # objects in their argument list and place them AFTER the field name,
    # producing correct GraphQL output:
    #
    #   feeInCents _skip(if: :skip_fee)
    #   -> feeInCents @skip(if: $skip_fee)
    #
    #   spread :InvoiceFields, _skip(if: :x)
    #   -> ...InvoiceFields @skip(if: $x)
    #
    #   spread(_skip(if: :x), on: :DraftInvoice) { draft_id }
    #   -> ... on DraftInvoice @skip(if: $x) { draftId }
    class Directive
      attr_reader :name, :args

      def initialize(name, args = {})
        @name = name.to_s.delete_prefix('_').freeze
        @args = args
      end

      def to_s
        return "@#{name}" if args.empty?

        formatted = args.map { |k, v| "#{k}: #{format_value(v)}" }.join(', ')
        "@#{name}(#{formatted})"
      end

      private

      # Symbols become variable references ($name); everything else is literal.
      def format_value(value)
        case value
        when Symbol                  then "$#{value}"
        when String                  then "\"#{value}\""
        when Numeric, TrueClass, FalseClass then value.to_s
        else value.to_s
        end
      end
    end
  end
end
