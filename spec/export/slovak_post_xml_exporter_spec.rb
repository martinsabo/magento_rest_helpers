# coding: utf-8
require 'magento_rest_helpers'
require 'support/fake_magento_1_7'
require 'nokogiri'

describe MagentoRestHelpers::Export::SlovakPostXmlExporter do

  before(:all) do
    MagentoRestHelpers::ApiClient.configure do |config|
      config.consumer_key = "oathkey"
      config.consumer_secret = "oathsecret"
      config.access_token = "token"
      config.access_token_secret = "tokensecret"
      config.site = "https://mymagento.com"
    end

    MagentoRestHelpers::Export::SlovakPostXmlExporter.configure do |config|
      config.shipping_methods_mapping = {
          "Dopravca - Slovenská pošta" => 1,
          "Dopravca - Kuriér" => 8
      }
      config.bank_account_nr = "1136855613/0900"
    end
  end

  context "magento 1.7 installation" do

    describe ".generate_sheet" do
      before(:each) do
        stub_request(:any, /mymagento.com/).to_rack(FakeMagento_1_7)
      end

      it "generates electronic sheet xml content" do
        exporter = MagentoRestHelpers::Export::SlovakPostXmlExporter
        sheet_content = exporter.generate_sheets("2014-09-01 20:15", "2014-10-05 20:20", 35)
        sheet_xml = Nokogiri::XML(sheet_content.first)
        sheet_xml.remove_namespaces!

        expect(sheet_xml.xpath("//Meno").first.text).to eq "Tristan Tester"
        expect(sheet_xml.xpath("//DruhZasielky").first.text).to eq "8"
        expect(sheet_xml.xpath("//CisloUctu").first.text)
            .to eq MagentoRestHelpers::Export::SlovakPostXmlExporter.configuration.bank_account_nr

      end

      it "generates electronic sheet xml content for 1st class letter" do
        exporter = MagentoRestHelpers::Export::SlovakPostXmlExporter
        sheet_content = exporter.generate_sheets("2014-08-01 20:15", "2014-08-10 20:20", 35)
        sheet_xml = Nokogiri::XML(sheet_content.first)
        sheet_xml.remove_namespaces!

        expect(sheet_xml.xpath("//DruhZasielky").first.text).to eq "1"
      end

    end


  end

end