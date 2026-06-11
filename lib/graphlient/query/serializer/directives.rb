module Graphlient
  class Query
    class Serializer
      module Directives
        # Matches _skip, _include, _myCustomDirective etc.
        # Does NOT match ___Fragment (three underscores -- checked first in method_missing).
        DIRECTIVE_PREFIX = /\A_[a-z]/.freeze

        private

        def directive?(method_name)
          method_name.to_s.match?(DIRECTIVE_PREFIX)
        end
      end
    end
  end
end
