module MagentoRestHelpers
  module Shipments
    include MagentoRestHelpers::ApiClient

    def fetch_order_data(conditions)
      get_data('/api/rest/orders', conditions)
    end

    def parse_xml_response(xml)
      result = []
      xml.xpath('/magento_api/data_item').each do |order|
        order_data = {}
        address_node = order.xpath("addresses/data_item[address_type = 'shipping']").first
        order_data[:address] = parse_xml_address(address_node)
        order_data[:cash_on_delivery] = parse_payment(order)
        result << order_data
      end
      result
    end

    def parse_xml_address(xml)
      {
        name: "#{xml.search('firstname').text} #{xml.search('lastname').text}",
        street: xml.search('street').text,
        city: xml.search('city').text,
        zip: xml.search('postcode').text,
        country: 'SK',
        phone: xml.search('telephone').text,
        organization: xml.search('company').text
      }
    end

    def parse_payment(order)
      method = order.xpath('payment_method').first
      if method.content == 'cashondelivery'
        return order.xpath('grand_total').first.content
      else
        return nil
      end
    end
  end
end
