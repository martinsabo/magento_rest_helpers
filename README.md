# MagentoRestHelpers

This game currently provide only basic helpers needed for export of shipments to 3rd party delivery service.
Some of the parts are usable when you want to create your own client class (api client and shipments modules).

## Installation

Add this line to your application's Gemfile:

    gem 'magento_rest_helpers'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install magento_rest_helpers

## Usage

Api client module needs to be configured before first use. In Rails app can be the configuration block placed into
initializer.

```ruby

MagentoRestHelpers::ApiClient.configure do |config|
  config.consumer_key = "some_key"
  config.consumer_secret = "some_secret"
  config.access_token = "oauth_token"
  config.access_token_secret = oauth_token_secret"
  config.site = "https://www.yourmagento.com"
end

```

### Example command line client script

In this example is used module created for Slovak post export. It needs to be configured first as well. Shipping methods
names from magento need to be paired to Slovak post method codes. This script saves xml files to harddrive for later import
to Slovak post shipments management tool [http://eph.posta.sk/].

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
  config.access_token_secret = oauth_token_secret"
  config.site = "https://www.yourmagento.com"
end

MagentoRestHelpers::Export::SlovakPostXmlExporter.configure do |config|
  config.shipping_methods_mapping = {
      "Dopravca - Slovenská pošta" => 1,
      "Dopravca - Kuriér" => 8
  }
  config.bank_account_nr = "111111111111/11111"
end

MagentoRestHelpers::Export::SlovakPostXmlExporter.generate_sheets(ARGV[0], ARGV[1], 10, ARGV[2])


```

### Magento setup

If you are using REST api first time in your magento installation, please double check your configuration before you
start to blame your own code.

### Useful how-to articles
[http://inchoo.net/magento/magento-rest-and-oauth-intro/]
[http://inchoo.net/magento/configure-magento-rest-and-oauth-settings/]

### Official magento docs
[http://www.magentocommerce.com/api/rest/authentication/oauth_configuration.html]
[http://www.magentocommerce.com/api/rest/get_filters.html]

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
