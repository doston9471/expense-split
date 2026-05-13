# frozen_string_literal: true

require "bigdecimal"

module MoneyHelpers
  module_function

  def cents_from_decimal(value)
    d = BigDecimal(value.to_s)
    (d * 100).round(0, BigDecimal::ROUND_HALF_UP).to_i
  rescue ArgumentError, TypeError
    raise ArgumentError, "invalid amount"
  end
end
