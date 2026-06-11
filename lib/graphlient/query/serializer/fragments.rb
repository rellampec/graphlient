module Graphlient
  class Query
    class Serializer
      module Fragments
        # Pattern for the legacy ___Const::Name triple-underscore convention.
        FRAGMENT_DEFINITION = /___(?<const>[A-Z][a-zA-Z0-9_]*(?:__[A-Z][a-zA-Z0-9_]*)*)/.freeze

        private

        def fragment?(method_name)
          method_name.to_s.start_with?('___')
        end

        def resolve_fragment_constant(value)
          return nil unless (match = value.to_s.match(FRAGMENT_DEFINITION))

          raw_const = match[:const].gsub('__', '::')
          @context[@last_block].eval(raw_const).tap do |const|
            next if const.is_a?(GraphQL::Client::FragmentDefinition)

            msg = "Expected constant #{raw_const} to be GraphQL::Client::FragmentDefinition. Given #{const.class}"
            raise Graphlient::Errors::Error, msg
          end
        end
      end
    end
  end
end
