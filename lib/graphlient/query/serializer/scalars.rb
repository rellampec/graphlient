module Graphlient
  class Query
    class Serializer
      module Scalars
        BUILT_IN_SCALAR_TYPES = {
          int: 'Int',
          float: 'Float',
          string: 'String',
          boolean: 'Boolean'
        }.freeze

        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          # Register a custom scalar type for use in variable declarations.
          #
          #   Graphlient::Query::Serializer.scalar(:date, 'Date')
          #
          # Typically called via the client configuration block:
          #   client = Graphlient::Client.new(url) do |c|
          #     c.scalar :date,    'Date'
          #     c.scalar :uuid,    'UUID'
          #     c.scalar :decimal, 'Decimal'
          #   end
          #
          # After registration, use the symbol in variable declarations:
          #   query(created_after: :date) { ... }  # -> query($createdAfter: Date)
          def scalar(sym, graphql_type)
            custom_scalar_types[sym.to_sym] = graphql_type.to_s
          end

          def custom_scalar_types
            @custom_scalar_types ||= {}
          end

          def all_scalar_types
            BUILT_IN_SCALAR_TYPES.merge(custom_scalar_types)
          end
        end

        private

        def scalar?(value)
          all_scalar_types.key?(value.to_s.delete('!').to_sym)
        end

        def scalar_type(value)
          str      = value.to_s
          base     = str.delete('!')
          non_null = str.end_with?('!')
          type     = all_scalar_types[base.to_sym]
          non_null ? "#{type}!" : type
        end

        def all_scalar_types
          self.class.all_scalar_types
        end
      end
    end
  end
end
