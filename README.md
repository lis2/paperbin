# Paperbin

TODO: 
To move papertrail's version records to file system as JSON format.

## Installation

Add this line to your application's Gemfile:

    gem 'paperbin'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install paperbin

### Queues

check worker - ENV['PAPERBIN_CHECK_QUEUE'] || 'default'
write worker - ENV['PAPERBIN_WRITE_QUEUE'] || 'default'

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
