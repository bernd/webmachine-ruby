module Webmachine
  class RangeEncoder
    include Enumerable

    def initialize(range_request, body)
      @range_request, @body = range_req, body

      # TODO Support multiple ranges.
      @range = @range_request.ranges.first

      @body = StringIO.new(@body) if @body.is_a?(String)
    end

    def prepare_response(response)
      if valid?
        response.headers['Content-Range'] = @range.response_header
        response.body = self if valid?
        response.code = 206
      end
    end

    def each
      io = @body.to_io

      io.seek(@range.start)
      remaining = @range.length

      while remaining > 0
        chunk = io.read([8192, remaining].min)
        break unless chunk
        remaining -= chunk.bytesize
        yield(chunk)
      end
    end

    private

    def valid?
      @body.respond_to?(:to_io) && @range
    end
  end
end
