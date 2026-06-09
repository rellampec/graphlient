module Graphlient
  class Query
    class Serializer
      module Evaluator
        private

        def evaluate(&block)
          @last_block = block || self
          (@context ||= {})[@last_block] ||= @last_block.binding
          instance_eval(&block)
        end
      end
    end
  end
end
