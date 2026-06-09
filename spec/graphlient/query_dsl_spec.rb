require 'spec_helper'

# Specs for DSL extensions: directives, inline fragments, fragment definitions,
# spread + directive, and custom scalar registration.
# These operate on the Query string builder only — no HTTP or schema access.

RSpec.describe Graphlient::Query do
  def build(&block)
    described_class.new(&block).to_s
  end

  # --- Directives -----------------------------------------------------------

  describe 'directives (_name convention → @name)' do
    it 'applies @skip to a field' do
      result = build do
        query(skip_fee: :boolean!) do
          invoice(id: 10) do
            id
            feeInCents _skip(if: :skip_fee)
          end
        end
      end
      expect(result).to include('@skip(if: $skip_fee)')
      expect(result).to include('feeInCents @skip(if: $skip_fee)')
    end

    it 'applies @include to a field' do
      result = build do
        query(show_fee: :boolean!) do
          invoice(id: 10) do
            feeInCents _include(if: :show_fee)
          end
        end
      end
      expect(result).to include('feeInCents @include(if: $show_fee)')
    end

    it 'applies multiple directives to one field' do
      result = build do
        query(skip_fee: :boolean!, show_desc: :boolean!) do
          invoice(id: 10) do
            feeInCents _skip(if: :skip_fee), _include(if: :show_desc)
          end
        end
      end
      expect(result).to include('@skip(if: $skip_fee)')
      expect(result).to include('@include(if: $show_desc)')
    end

    it 'applies a directive with no arguments' do
      result = build do
        query do
          invoice(id: 10) do
            id _deprecated
          end
        end
      end
      expect(result).to include('id @deprecated')
    end

    it 'does not confuse ___ fragment constant with a directive' do
      result = build do
        query do
          invoice(id: 10) { id }
        end
      end
      expect(result).not_to include('@__')
    end
  end

  # --- Fragment spreads with directives ------------------------------------

  describe 'spread with directive' do
    it 'appends directive after the spread name' do
      result = build do
        query(skip_invoice: :boolean!) do
          spread :InvoiceFields, _skip(if: :skip_invoice)
        end
      end
      expect(result).to include('...InvoiceFields @skip(if: $skip_invoice)')
    end

    it 'spread without directive is unchanged' do
      result = build do
        query { spread :InvoiceFields }
      end
      expect(result).to include('...InvoiceFields')
      expect(result).not_to include('@')
    end
  end

  # --- Inline fragments ----------------------------------------------------

  describe 'on(:Type) — inline fragment' do
    it 'generates ... on Type { }' do
      result = build do
        query do
          invoice(id: 10) do
            on(:PaidInvoice) do
              amountPaid
            end
            on(:UnpaidInvoice) do
              amountDue
            end
          end
        end
      end
      expect(result).to include('... on PaidInvoice')
      expect(result).to include('amountPaid')
      expect(result).to include('... on UnpaidInvoice')
      expect(result).to include('amountDue')
    end

    it 'applies a directive on the inline fragment' do
      result = build do
        query(skip_draft: :boolean!) do
          invoice(id: 10) do
            on(:DraftInvoice, _skip(if: :skip_draft)) do
              draftId
            end
          end
        end
      end
      expect(result).to include('... on DraftInvoice @skip(if: $skip_draft)')
      expect(result).to include('draftId')
    end

    it 'inline fragment without block (type check only)' do
      result = build do
        query { on(:Invoice) }
      end
      expect(result).to include('... on Invoice')
    end
  end

  # --- Fragment definitions ------------------------------------------------

  describe 'fragment(:Name, on: :Type)' do
    it 'appends the fragment definition after the main query' do
      result = build do
        fragment(:InvoiceFields, on: :Invoice) do
          id
          feeInCents
        end
        query do
          invoice(id: 10) do
            spread :InvoiceFields
          end
        end
      end
      expect(result).to include('...InvoiceFields')
      expect(result).to include('fragment InvoiceFields on Invoice')
      expect(result).to include('feeInCents')
    end

    it 'separates query and fragment with a blank line' do
      result = build do
        fragment(:F, on: :T) { id }
        query { spread :F }
      end
      parts = result.split("\n\n")
      expect(parts.length).to eq 2
      expect(parts.last).to start_with('fragment F on T')
    end

    it 'supports multiple fragment definitions' do
      result = build do
        fragment(:FragA, on: :TypeA) { field_a }
        fragment(:FragB, on: :TypeB) { field_b }
        query { spread :FragA; spread :FragB }
      end
      expect(result).to include('fragment FragA on TypeA')
      expect(result).to include('fragment FragB on TypeB')
    end
  end

  # --- Custom scalar registration ------------------------------------------

  describe 'custom scalar registration' do
    before { described_class::Serializer.scalar(:date, 'Date') }

    it 'uses the registered type in variable declarations' do
      result = build do
        query(created_after: :date) do
          invoices(created_after: :created_after) { id }
        end
      end
      # Variable names are not camelized — snake_case keys output as-is
      expect(result).to include('$created_after: Date')
    end

    it 'supports non-null custom scalars with !' do
      result = build do
        query(started_at: :date!) do
          invoices(started_at: :started_at) { id }
        end
      end
      expect(result).to include('$started_at: Date!')
    end

    it 'built-in scalars still work alongside custom ones' do
      result = build do
        query(id: :int, created_after: :date) do
          invoice(id: :id) { id }
        end
      end
      expect(result).to include('$id: Int')
      expect(result).to include('$created_after: Date')
    end
  end
end
