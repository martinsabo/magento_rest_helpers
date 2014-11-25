# coding: utf-8
module MagentoRestHelpers
  module Export
    module SlovakPostXmlExporter
      extend MagentoRestHelpers::Shipments

      class << self
        attr_accessor :configuration
      end

      def self.configure
        self.configuration ||= Configuration.new
        yield(configuration)
      end

      class Configuration
        attr_accessor :shipping_methods_mapping, :bank_account_nr
      end

      # DruhZasielky
      # ID  Popis
      # 1   Doporučený list
      # 2   Poistený list
      # 3   Úradná zásielka
      # 4   Balík
      # 8   Expres kuriér
      # 10  EMS MS
      # 11  EPG – obchodný balík MS
      # 12  Doporučený list slepecký
      # 14  Zmluvný balík
      # 15  Easy Expres
      SHEET_SKELETON = "
                      <EPH verzia='3.0'>
                        <InfoEPH>
                          <Uhrada></Uhrada>
                          <Odosielatel></Odosielatel>
                          <DruhZasielky></DruhZasielky>
                        </InfoEPH>
                        <Zasielky>
                        </Zasielky>
                      </EPH>"


      def self.generate_sheets(from_date=nil, to_date=nil, limit=nil, file_root_path=nil, order_status="Processing")

        # conversion to UTC needed for magento rest api filters
        # (documentation to accepted magento datetime formats is non existent/well hidden)
        from_date = from_date.nil? ? nil : Time.strptime(from_date, "%Y-%m-%d %H:%M").utc.strftime("%Y-%m-%d %H:%M")
        to_date = to_date.nil? ? nil : Time.strptime(to_date, "%Y-%m-%d %H:%M").utc.strftime("%Y-%m-%d %H:%M")

        unless file_root_path.nil?
          raise "Dir #{file_root_path} does not exist." unless File.directory?(file_root_path)
        end

        conditions = {filter: [{attr_name: 'status', operator: 'in', value: order_status}], limit: limit}
        conditions[:filter] << {attr_name: 'created_at', operator: 'gt', value: from_date} unless from_date.nil?
        conditions[:filter] << {attr_name: 'created_at', operator: 'lt', value: to_date} unless to_date.nil?

        order_xml = fetch_order_data(conditions)
        data = parse_xml_response(order_xml)

        unless data.empty?
          contents = compile_result_xml(data)
          unless file_root_path.nil?
            contents.each{|content| save_file(content, file_root_path, from_date)}
          else
            return contents
          end
        else
          puts "No orders in selected date range (#{from_date} UTC - #{to_date} UTC) with '#{order_status}' status."
        end
      end

      private

      def self.save_file(content, file_root_path, from_date)
        filename = "podaciharok#{from_date.gsub(/\W/, '')}.xml"
        file_path = File.join(file_root_path, filename)
        File.open(file_path, 'w') { |f| f.write(content) }
      end

      # shipments module method replacement
      # groups shipments by shipping description
      def self.parse_xml_response(xml)
        result = Hash[self.configuration.shipping_methods_mapping.keys.map{|key| [key, []]}]
        xml.xpath('/magento_api/data_item').each do |order|
          order_data = {}
          order_data[:address] = parse_xml_address(order.xpath("addresses/data_item[address_type = 'shipping']").first)
          order_data[:cash_on_delivery] = parse_payment(order)

          shipping_method = order.xpath("shipping_description").first.content
          unless result[shipping_method].nil?
            result[shipping_method] << order_data
          else
            raise RuntimeError.new("Shipping method in downloaded data is missing in configuration. Method name: #{shipping_method}.")
          end
        end
        result.delete_if{|k,v| v==[]}
      end

      def self.to_slovak_node_names(address_hash)
        mapping = {
            name: 'Meno',
            street: 'Ulica',
            city: 'Mesto',
            zip: 'PSC',
            country: 'Krajina',
            phone: 'Telefon',
            organization: 'Organizacia',
        }
        result = {}
        address_hash.each_pair { |key, value| result[mapping[key]] = value }
        result
      end

      def self.compile_result_xml(data)
        xml_contents = []
        data.each_pair do |shipping_type, records|
          result_xml = Nokogiri::XML(SHEET_SKELETON, nil, 'UTF-8', &:noblanks)
          shipments_node = result_xml.xpath('//Zasielky').first

          records.each do |record|
            shipments_node << compile_shipment(record, result_xml)
          end

          result_xml.xpath("//DruhZasielky").first.content = self.configuration.shipping_methods_mapping[shipping_type]
          result_xml.root.add_namespace(nil, "http://ekp.posta.sk/LOGIS/Formulare/Podaj_v03")
          xml_contents << fix_xml_linebreaks(result_xml.to_xml)
        end
        xml_contents
      end

      # make xml output more readable
      def self.fix_xml_linebreaks(xml_string)
        Nokogiri::XML(xml_string, nil, 'UTF-8', &:noblanks).to_xml
      end

      def self.compile_shipment(data, result_xml)
        shipment = result_xml.create_element('Zasielka')
        address = result_xml.create_element('Adresat')
        shipment << address

        to_slovak_node_names(data[:address]).each_pair do |node_name, value|
          node = result_xml.create_element(node_name)
          node.content = value
          address << node
        end

        unless data[:cash_on_delivery].nil?
          info = result_xml.create_element('Info')
          shipment << info
          services = result_xml.create_element('PouziteSluzby')
          service = result_xml.create_element('Sluzba')
          service.content = "F" # Krehke by default
          services << service
          shipment << services

          account_nr = result_xml.create_element('CisloUctu')
          account_nr.content = self.configuration.bank_account_nr
          info << account_nr

          cod_price = result_xml.create_element('CenaDobierky')
          # rounded - magento returns 4 decimal places
          cod_price.content = '%.2f' % data[:cash_on_delivery].to_f
          info << cod_price
        end

        shipment
      end
    end
  end
end