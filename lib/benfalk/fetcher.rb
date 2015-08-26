require 'benfalk/fetcher/version'
require 'net/http'

module Benfalk
  class Fetcher
    attr_reader :urls, :retry_limit
    RetryLimitExceeded = Class.new(Exception)
    SERVER_ERROR_CODES = (500..599)

    def initialize(urls, retry_limit: 5)
      @urls = urls
      @retry_limit = retry_limit
    end

    def call
      uris.map do |uri|
        fetch(uri)
      end
    end

    private

    def fetch(uri)
      retry_count = 1
      loop do
        response = Net::HTTP.get_response(uri)
        return response unless SERVER_ERROR_CODES.include? response.code.to_i
        fail RetryLimitExceeded if retry_count > retry_limit
        sleep(2 ** retry_count)
        retry_count += 1
      end
    end

    def uris
      urls.map(&method(:URI))
    end
  end
end
