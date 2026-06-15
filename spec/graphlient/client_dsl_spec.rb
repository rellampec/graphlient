require 'spec_helper'

describe Graphlient::Client do
  let(:client) { described_class.new('http://example.com/graphql') }

  describe '#to_query_string' do
    it 'returns a String' do
      result = client.to_query_string do
        query do
          invoice(id: 10) do
            id
            feeInCents
          end
        end
      end
      expect(result).to be_a String
    end

    it 'builds a simple query without HTTP or schema access' do
      result = client.to_query_string do
        query do
          invoice(id: 10) do
            id
            feeInCents
          end
        end
      end
      expect(result).to include('query')
      expect(result).to include('invoice')
      expect(result).to include('feeInCents')
    end

    it 'builds a parameterized query with variable declarations' do
      result = client.to_query_string do
        query(id: :int) do
          invoice(id: :id) do
            id
            feeInCents
          end
        end
      end
      expect(result).to include('$id: Int')
      expect(result).to include('invoice(id: $id)')
    end

    it 'builds a mutation query string' do
      result = client.to_query_string do
        mutation(input: :CreateInvoiceInput!) do
          createInvoice(input: :input) do
            invoice do
              id
            end
            errors
          end
        end
      end
      expect(result).to include('mutation')
      expect(result).to include('createInvoice')
      expect(result).to include('$input: CreateInvoiceInput!')
    end

    it 'does not interact with the HTTP adapter' do
      expect_any_instance_of(Graphlient::Adapters::HTTP::FaradayAdapter).not_to receive(:execute)
      client.to_query_string do
        query do
          invoice(id: 1) { id }
        end
      end
    end

    context 'with spread helper' do
      it 'includes a named fragment spread in the query string' do
        result = client.to_query_string do
          query do
            invoice(id: 10) do
              spread :InvoiceFields
            end
          end
        end
        expect(result).to include('...InvoiceFields')
      end

      it 'supports multiple spreads at the same level' do
        result = client.to_query_string do
          query do
            nodes do
              spread :FragmentA
              spread :FragmentB
            end
          end
        end
        expect(result).to include('...FragmentA')
        expect(result).to include('...FragmentB')
      end
    end

    it 'builds a query with a directive' do
      result = client.to_query_string do
        query(skip_fee: :boolean!) do
          invoice(id: 10) do
            id
            feeInCents _skip(if: :skip_fee)
          end
        end
      end
      expect(result).to include('feeInCents @skip(if: $skip_fee)')
      expect(result).to include('$skip_fee: Boolean!')
    end

    it 'builds a query with an inline fragment' do
      result = client.to_query_string do
        query do
          invoice(id: 10) do
            spread(on: :PaidInvoice) { amountPaid }
          end
        end
      end
      expect(result).to include('... on PaidInvoice')
      expect(result).to include('amountPaid')
    end

    it 'builds a query with an inline fragment definition' do
      result = client.to_query_string do
        fragment(:InvoiceFields, on: :Invoice) do
          id
          feeInCents
        end
        query { invoice(id: 10) { spread :InvoiceFields } }
      end
      expect(result).to include('...InvoiceFields')
      expect(result).to include('fragment InvoiceFields on Invoice')
    end
  end

  describe '#scalar (custom scalar registration)' do
    let(:client_with_scalars) do
      described_class.new('http://example.com/graphql') do |c|
        c.scalar :date, 'Date'
        c.scalar :uuid, 'UUID'
      end
    end

    it 'registers custom scalars via the client block' do
      result = client_with_scalars.to_query_string do
        query(created_after: :date, id: :uuid!) do
          invoices(created_after: :created_after) { total }
        end
      end
      expect(result).to include('$created_after: Date')
      expect(result).to include('$id: UUID!')
    end
  end
end
