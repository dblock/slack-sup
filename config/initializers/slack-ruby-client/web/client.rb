module Slack
  module Web
    class PaginatedResult
      include Enumerable

      attr_reader :client
      attr_reader :method
      attr_reader :params

      def initialize(client, method, params = {})
        @client = client
        @method = method
        @params = params
      end

      def each
        next_cursor = nil
        loop do
          query = { limit: 100 }.merge(params).merge(cursor: next_cursor)
          response = client.send(method, query)
          yield response
          next_cursor = response.response_metadata.next_cursor
          break if next_cursor.blank?
        end
      end
    end

    class Client
      def paginate(method, params = {})
        PaginatedResult.new(self, method, params)
      end
    end
  end
end
