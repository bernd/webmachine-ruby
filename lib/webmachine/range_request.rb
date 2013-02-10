module Webmachine
  class RangeRequest
    class Range < Struct.new(:range, :size)
      def start
        range.begin
      end

      def length
        range.end - range.begin + 1
      end

      def response_header
        "bytes %d-%d/%d" % [range.begin, range.end, size]
      end
    end

    attr_reader :ranges

    def initialize(range_header, size)
      @ranges = byte_ranges(range_header, size)
    end

    private

    # Parses the "Range:" header, if present, into an array of Range objects.
    # Returns nil if the header is missing or syntactically invalid.
    # Returns an empty array if none of the ranges are satisfiable.
    # From rack lib/rack/utils.rb
    def byte_ranges(header, size)
      return unless header =~ /bytes=([^;]+)/
      ranges = []
      $1.split(/,\s*/).each do |range_spec|
        return nil  unless range_spec =~ /(\d*)-(\d*)/
        r0,r1 = $1, $2
        if r0.empty?
          return nil  if r1.empty?
          # suffix-byte-range-spec, represents trailing suffix of file
          r0 = size - r1.to_i
          r0 = 0  if r0 < 0
          r1 = size - 1
        else
          r0 = r0.to_i
          if r1.empty?
            r1 = size - 1
          else
            r1 = r1.to_i
            return nil  if r1 < r0  # backwards range is syntactically invalid
            r1 = size-1  if r1 >= size
          end
        end
        ranges << Range.new((r0..r1), size)  if r0 <= r1
      end
      ranges
    end
  end
end
