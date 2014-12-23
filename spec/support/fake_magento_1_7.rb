require 'sinatra/base'

class FakeMagento_1_7 < Sinatra::Base

  get '/api/rest/:resource' do
    response_from_file 200, params[:resource], response_content_type(request), @request.params
  end

  private

  def response_from_file(response_code, file_name, format, params)
    content_type format
    status response_code

    if params['filter'].nil?
      return fixture_content(file_name, format)
    end

    fixture_content(file_name, format, *filter_dates_from_params(params))
  end

  def fixture_content(file_name, format, from_date = nil, to_date = nil)
    if from_date.nil? or to_date.nil?
      full_name = file_name
      puts "\n      Using default #{file_name}.#{format} fixture"
    else
      full_name = "#{file_name}_#{from_date}_#{to_date}"
    end

    file_path = File.join(File.dirname(__FILE__), "/response_fixtures/#{full_name}.#{format}")
    if File.exist?(file_path)
      return File.open(file_path, 'rb').read
    else
      fail("Fixture file not found. Missing: #{file_path}")
    end

  end

  def filter_dates_from_params(params)
    from_hash = params['filter'].select do |k, v|
      v['attribute'] == 'created_at' and params['filter'][k].keys.include?('gt')
    end
    from_date = from_hash.empty? ? nil : from_hash.values.first['gt'].split(' ')[0]

    to_hash = params['filter'].select do |k, v|
      v['attribute'] == 'created_at' and params['filter'][k].keys.include?('lt')
    end
    to_date = to_hash.empty? ? nil : to_hash.values.first['lt'].split(' ')[0]

    [from_date, to_date]
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
