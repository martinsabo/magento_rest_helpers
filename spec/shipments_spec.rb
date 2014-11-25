require 'magento_rest_helpers'
require 'support/fake_magento_1_7'

describe MagentoRestHelpers::Shipments do

  class ShipmentsClient
    include MagentoRestHelpers::Shipments
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

  let(:client){ShipmentsClient.new}

  context "magento 1.7 installation" do

    describe ".parse_xml_response" do
      before(:each) do
        stub_request(:any, /mymagento.com/).to_rack(FakeMagento_1_7)
      end

      it "returns shipment data array" do
        xml_data = client.fetch_order_data({})
        data = client.parse_xml_response(xml_data)

        expect(data.count).to eq 1
        expect(data.first[:address][:name]).to eq "Tristan Tester"
        expect(data.first[:cash_on_delivery]).to eq "23.9000"
      end

    end
  end

end