require 'magento_rest_helpers'
require 'support/fake_magento_1_7'

describe MagentoRestHelpers::ApiClient do

  class Client
    include MagentoRestHelpers::ApiClient
  end

  before(:all) do
    MagentoRestHelpers::ApiClient.configure do |config|
      config.consumer_key = "oathkey"
      config.consumer_secret = "oathsecret"
      config.access_token = "token"
      config.access_token_secret = "tokensecret"
      config.site = "https://mymagento.com"
    end
  end


  let(:api_client){Client.new}

  context "magento 1.7 installation" do

    describe ".get_data" do
        before(:each) do
          stub_request(:any, /mymagento.com/).to_rack(FakeMagento_1_7)
        end

        it "returns xml response by default" do
          xml = api_client.get_data('/api/rest/orders', {limit: 1})
          expect(xml.xpath('/magento_api/data_item').count).to eq 1
        end

        it "returns json response when requested" do
          json = api_client.get_data('/api/rest/orders', {limit: 1}, response_format: :json)
          expect(json['437']['status']).to eq 'processing'
        end
    end

    describe ".magento_query_string" do

      it "returns correct url params string" do
        conditions = {
            filter: [{attr_name: 'created_at', operator: 'gt', value: '2014-05-12'},
            {attr_name: 'created_at', operator: 'lt', value: '2014-05-24'},
            {attr_name: 'status', operator: 'in', value: 'Processing'}],
        }
        params = api_client.magento_query_string(conditions)
        expect(params).to eq "filter[1][attribute]=created_at&filter[1][gt]=2014-05-12&filter[2][attribute]=created_at"\
                             "&filter[2][lt]=2014-05-24&filter[3][attribute]=status&filter[3][in]=Processing"

        conditions[:limit] = 25
        params = api_client.magento_query_string(conditions)
        expect(params).to eq "filter[1][attribute]=created_at&filter[1][gt]=2014-05-12&filter[2][attribute]=created_at"\
                             "&filter[2][lt]=2014-05-24&filter[3][attribute]=status&filter[3][in]=Processing&limit=25"
      end

      it "sets single limit condition" do
        params = api_client.magento_query_string({limit: 10})
        expect(params).to eq ("limit=10")
      end

      it "validates operators" do
        expect{api_client.magento_query_string({filter: [{attr_name: "test", operator:"wrong", value:"123"}]})}
            .to raise_error(RuntimeError, /Unknown magento operator present in filters array./)
      end

    end

  end

end