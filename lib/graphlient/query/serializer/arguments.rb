module Graphlient
  class Query
    class Serializer
      module Arguments
        private

        def variable_processor
          @variable_processor ||= ->(k, v) { "$#{k}: #{variable_string(v)}" }
        end

        # Translate a DSL variable type symbol to its GraphQL type string.
        # :id/:id! -> ID/ID!   :int -> Int   :date -> Date (if registered)   [:int] -> [Int]
        def variable_string(val)
          case val
          when :id, :id!
            val.to_s.upcase
          when ->(v) { scalar?(v) }
            scalar_type(val)
          when Array
            "[#{variable_string(val.first)}]"
          else
            val.to_s
          end
        end

        # Separate Directive objects from regular field arguments.
        def field_args(args)
          args.reject { |a| a.is_a?(Directive) }
        end

        def directive_args(args)
          args.select { |a| a.is_a?(Directive) }
        end

        def hash_arg(args)
          args.detect { |arg| arg.is_a?(Hash) }
        end

        def args_str(hash_args, arg_processor: nil)
          hash_args.map do |k, v|
            arg_processor ? arg_processor.call(k, v) : argument_string(k, v)
          end.join(', ')
        end

        def argument_string(key, val)
          "#{key}: #{argument_value_string(val)}"
        end

        def argument_value_string(value)
          case value
          when String  then "\"#{value}\""
          when Numeric then value.to_s
          when Array   then "[#{value.map { |v| argument_value_string(v) }.join(', ')}]"
          when Hash    then "{ #{value.map { |k, v| "#{k}: #{argument_value_string(v)}" }.join(', ')} }"
          when Symbol  then symbol_argument_value(value)
          else
            value
          end
        end

        def symbol_argument_value(value)
          @variables.respond_to?(:key?) && @variables.key?(value) ? "$#{value}" : value.to_s.camelize(:lower)
        end
      end
    end
  end
end
