require_relative 'query/serializer'

module Graphlient
  # Public interface for building GraphQL query strings via a DSL block.
  # Delegates all string-building work to Query::Serializer.
  #
  # Usage:
  #   Graphlient::Query.new do
  #     query do
  #       invoice(id: 10) { id; fee_in_cents }
  #     end
  #   end.to_s
  class Query
    # Register a custom scalar type for variable declarations.
    # Delegates to Serializer so client configuration works:
    #   client = Graphlient::Client.new(url) { |c| c.scalar :date, 'Date' }
    def self.scalar(sym, graphql_type)
      Serializer.scalar(sym, graphql_type)
    end

    def initialize(&block)
      @serializer = Serializer.new(&block)
    end

    def to_s
      @serializer.to_s
    end
  end
end
