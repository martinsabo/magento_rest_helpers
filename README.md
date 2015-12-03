# Magento rest helpers

This gem currently provides only basic helpers needed for export of shipments to 3rd party delivery service.
Some of the parts (api client and shipments module) can be helpful when you want to create your own client class or module.

## Installation

Add this line to your application's Gemfile:

    gem 'magento_rest_helpers', :git => 'https://github.com/martinsabo/magento_rest_helpers.git'

And then execute:

    $ bundle

## Usage

Api client module needs to be configured first. In Rails app you can place the configuration block into
initializer.

```ruby

MagentoRestHelpers::ApiClient.configure do |config|
  config.consumer_key = "some_key"
  config.consumer_secret = "some_secret"
  config.access_token = "oauth_token"
  config.access_token_secret = "oauth_token_secret"
  config.site = "https://www.yourmagento.com"
end

```

### Example command line client script

This example script is using module created for Slovak post export. Magento's shipping
methods need to be paired to Slovak post's shipping method codes in configuration block. This example saves xml files to harddrive for later import
to Slovak post shipments management tool http://eph.posta.sk/.

```ruby
# coding: utf-8
require 'magento_rest_helpers'

ARGV.each do|a|
  puts "Argument: #{a}"
end

MagentoRestHelpers::ApiClient.configure do |config|
  config.consumer_key = "some_key"
  config.consumer_secret = "some_secret"
  config.access_token = "oauth_token"
  config.access_token_secret = "oauth_token_secret"
  config.site = "https://www.yourmagento.com"
end

MagentoRestHelpers::Export::SlovakPostXmlExporter.configure do |config|
  config.shipping_methods_mapping = {
      "Dopravca - Slovenská pošta" => 1,
      "Dopravca - Kuriér" => 8
  }
  config.bank_account_nr = "111111111111/11111"
end

sheets = MagentoRestHelpers::Export::SlovakPostXmlExporter.generate_sheets(ARGV[0], ARGV[1], 10)
MagentoRestHelpers::Export::SlovakPostXmlExporter.save_files(sheets, ARGV[2], ARGV[0])

```

### Magento setup

If you are using REST api for the first time with your magento installation, please double check your magento configuration before you
start to blame your own code.

### Useful how-to articles

* http://inchoo.net/magento/magento-rest-and-oauth-intro/
* http://inchoo.net/magento/configure-magento-rest-and-oauth-settings/
* http://www.aschroder.com/2012/04/introduction-to-the-magento-rest-apis-with-oauth-in-version-1-7/

### Official magento docs

* http://www.magentocommerce.com/api/rest/authentication/oauth_configuration.html
* http://www.magentocommerce.com/api/rest/get_filters.html

## Troubleshooting

If you are getting 404 don't forget to check if you have proper rewrite rule in your webserver config.

```
   #Example rule for nginx:

   location /api {
      rewrite ^/api/rest /api.php?type=rest last;
   }

```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
