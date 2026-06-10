RSpec.shared_context 'Dummy Client', shared_context: :metadata do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  let(:endpoint) { 'http://graph.biz/graphql' }

  let(:headers) do
    {
      'Authorization' => 'Bearer 1231',
      'Content-Type' => 'application/json'
    }
  end

  # Route all requests through the Sinatra dummy app via WebMock's to_rack adapter.
  # This is more reliable than configuring Faraday::Adapter::Rack directly because
  # WebMock intercepts Faraday requests before they reach the adapter layer on some
  # Ruby/gem version combinations; to_rack routes at the WebMock level instead.
  before do
    stub_request(:post, endpoint)
      .with(headers: { 'Authorization' => 'Bearer 1231' })
      .to_rack(app)
  end

  # No schema_path: the to_rack stub above routes schema introspection to the
  # Sinatra app as well, so graphql-client gets the full live schema including
  # test-only fields (executionErrorInvoice, partialSuccess etc.).
  let(:client) do
    Graphlient::Client.new(endpoint, headers: headers)
  end
end
