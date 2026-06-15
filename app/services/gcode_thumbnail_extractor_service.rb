class GcodeThumbnailExtractorService
  def initialize(file:)
    @file = file
    @remaining = nil
  end

  def call
    data = ""
    while (line = @file.gets("\n"))
      if @remaining.nil?
        if line =~ /thumbnail[^\n]*begin[^\n]*? ([0-9]+)$/
          @remaining = $1.to_i
        end
      elsif line =~ /thumbnail[^\n]*end$/ || @remaining <= 0
        @remaining = nil
        break
      else
        new_data = line.gsub(/^;\s*/, "").chomp
        data += new_data
        @remaining -= new_data.length
      end
    end
    StringIO.new(Base64.strict_decode64(data))
  end
end
