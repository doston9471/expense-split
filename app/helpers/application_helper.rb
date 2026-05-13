module ApplicationHelper
  def format_money(cents, currency = "USD")
    return "—" if cents.nil?

    value = BigDecimal(cents) / 100
    "#{currency} #{sprintf('%.2f', value.to_f)}"
  end
end
