module Slack
  module Web
    class PaginatedResult
      include Enumerable

      attr_reader :client, :method, :params

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
          break unless response.response_metadata

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
