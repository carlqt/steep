class Conference
  # @dynamic title, year
  attr_reader :title
  attr_reader :year

  def initialize(title:, year:)
    @title = title
    @year = year
  end

  def run(input)
    if input.respond_to?(:foo) && input.respond_to?(:bar)
      "Input is a length -> #{input.foo}:#{input.bar}"
    end

    if input.is_a?(String)
      input.upcase
    end

    return "Input is a string"
  end
end
