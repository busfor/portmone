class Portmone::Responses::OrderStatus < Portmone::Responses::BaseResponse
  #
  # статусы:
  # CREATED - клиент перешел на страницу 3Ds
  # PREAUTH - деньги успешно заблокированы на счету
  # PAYED - деньги списаны
  # REJECTED - платеж не удалось провести или отмена авторизации
  # RETURN - успешный возврат
  #
 
  %i(bill_date
     pay_time
     pay_order_time
     order_id
     shop_order_number
     description
     auth_code
     status
     error_code
     error_message).each do |key|

    define_method(key) do
      order.send key
    end
  end

  def amount
    transactions.select(&:paid?)
                .map { |t| t.bill_amount }
                .inject(:+) || transactions.first&.bill_amount
  end

  def reversed_amount
    transactions.select(&:reversed?)
                .map { |t| t.bill_amount }
                .inject(:+) || 0
  end

  def actual_amount
    amount + reversed_amount
  end

  # статусы "оплачено" и "авторизовано"
  def paid?
    transactions.any?(&:paid?)
  end

  def reversed?
    transactions.any?(&:reversed?)
  end

  def success?
    order.present? && error_code == '0'
  end

  def transactions
    @transactions ||= begin
      if data
        data.map do |h|
          Portmone::Transaction.new(h.merge(timezone: @timezone, currency: @currency))
        end
      else
        []
      end
    end
  end

  def order
    @order ||= begin
      if data
        Portmone::Transaction.new(data.first.merge(data.last).merge(timezone: @timezone, currency: @currency))
      else
        Portmone::Transaction.new(timezone: @timezone, currency: @currency)
      end
    end
  end

private

  def data
    data = @xml_data.dig('portmoneresult', 'orders', 'order') || @xml_data.dig('portmoneresult', 'order')
    data = [data] if data.is_a?(Hash) # cannot use Array() on Hash
    data
  end
end
