require 'sinatra/base'


class FakeMagento_1_7 < Sinatra::Base

  get '/api/rest/orders' do
    response_from_file 200, 'orders', response_content_type(request), @request.params
  end

  private

  def response_from_file(response_code, file_name, format, params)
    content_type format
    status response_code

    unless params['filter'].nil?
       from_date, to_date = filter_dates_from_params(params)

       file_path = File.dirname(__FILE__) + "/response_fixtures/#{file_name}_#{from_date}_#{to_date}.#{format}"
       if File.exist?(file_path)
         return File.open(file_path, 'rb').read
       else
         puts "\nFixture file not found, using the default one. Missing: #{file_path}"
       end
    end
    File.open(File.dirname(__FILE__) + "/response_fixtures/#{file_name}.#{format}", 'rb').read
  end

  def filter_dates_from_params(params)
    from_hash = params['filter'].select{|k,v| v['attribute'] == 'created_at' and params['filter'][k].keys.include?('gt')}
    from_date = from_hash.empty? ? nil : from_hash.values.first['gt'].split(" ")[0]

    to_hash = params['filter'].select{|k,v| v['attribute'] == 'created_at' and params['filter'][k].keys.include?('lt')}
    to_date = to_hash.empty? ? nil : to_hash.values.first['lt'].split(" ")[0]

    return from_date, to_date
  end

  def response_content_type(request)
    case request.env['HTTP_ACCEPT']
      when 'application/xml'
        return :xml
      when 'application/json'
        return :json
     end
  end
end