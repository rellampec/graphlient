require 'spec_helper'

describe Graphlient::Client do
  describe 'parse and execute' do
    module Graphlient::Client::Spec
      # schema_path avoids an HTTP schema fetch at file-load time.
      # No Rack adapter needed here; parsing is local and execution is handled
      # by the stub_request below.
      Client = Graphlient::Client.new(
        'http://graph.biz/graphql',
        schema_path: 'spec/support/fixtures/invoice_api.json',
        headers: { 'Authorization' => 'Bearer 1231' },
        allow_dynamic_queries: false
      )

      StringQuery = Client.parse <<~GRAPHQL
        query($some_id: Int) {
          invoice(id: $some_id) {
            id
            feeInCents
          }
        }
      GRAPHQL

      BlockQuery = Client.parse do
        query(some_id: :int) do
          invoice(id: :some_id) do
            id
            feeInCents
          end
        end
      end
    end

    # Route execution requests through the Sinatra dummy app via WebMock.
    # to_rack works reliably across Ruby/gem versions; Faraday::Adapter::Rack
    # can be intercepted before dispatch on some Ruby 3.x + WebMock combinations.
    before do
      stub_request(:post, 'http://graph.biz/graphql')
        .with(headers: { 'Authorization' => 'Bearer 1231' })
        .to_rack(Sinatra::Application)
    end

    it 'defaults allow_dynamic_queries to false' do
      expect(Graphlient::Client::Spec::Client.send(:client).allow_dynamic_queries).to be false
    end

    context 'with string-based queries' do
      it 'parses a string query to an OperationDefinition' do
        expect(Graphlient::Client::Spec::StringQuery.class).to be GraphQL::Client::OperationDefinition
      end

      it 'sets the OperationDefinition that came from a string to have a name' do
        expect(Graphlient::Client::Spec::StringQuery.definition_name).to eql 'Graphlient__Client__Spec__StringQuery'
      end
    end

    context 'with both string- and block-based queries' do
      it 'gets identical results parsing equivalent string- and block-based queries' do
        block_response  = Graphlient::Client::Spec::Client.execute(Graphlient::Client::Spec::BlockQuery, some_id: 42)
        string_response = Graphlient::Client::Spec::Client.execute(Graphlient::Client::Spec::StringQuery, some_id: 42)
        expect(string_response.to_h).to eq block_response.to_h
      end
    end

    context 'executing a query' do
      it 'succeeds with expected feeInCents' do
        response = Graphlient::Client::Spec::Client.execute(Graphlient::Client::Spec::BlockQuery, some_id: 42)
        invoice  = response.data.invoice
        expect(invoice.id).to eq '42'
        expect(invoice.fee_in_cents).to eq 20_000
      end
    end
  end
end
