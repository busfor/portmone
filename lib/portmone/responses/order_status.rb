class Portmone::Responses::OrderStatus < Portmone::Responses::BaseResponse
  TIMEZONE = 'Europe/Kiev'.freeze

  def bill_date
    Date.parse(order['bill_date'])
  end

  def pay_date
    ActiveSupport::TimeZone[TIMEZONE].parse(order['pay_date'])
  end

  def pay_order_date
    ActiveSupport::TimeZone[TIMEZONE].parse(order['pay_order_date']) rescue nil
  end

  def bill_amount
    Money.from_amount(order['bill_amount'].to_f, @currency)
  end

  %i(shop_bill_id
     shop_order_number
     description
     auth_code
     status
     error_code
     error_message).each do |key|

    define_method(key) do
      order&.dig(key.to_s)
    end
  end

  def success?
    order.present? && error_code == '0'
  end

private

  def order
    data = @xml_data.dig('portmoneresult', 'orders', 'order') || @xml_data.dig('portmoneresult', 'order')

    if data.is_a?(Hash)
      data
    elsif data.is_a?(Array)
      data.last
    end
  end
end
