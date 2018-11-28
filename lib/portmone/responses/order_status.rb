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
                .inject(:+) || transactions.first.bill_amount
  end

  def reversed_amount
    transactions.select(&:reversed?)
                .map { |t| t.bill_amount }
                .inject(:+) || 0
  end

  def actual_amount
    amount + reversed_amount
  end

  def paid?
    transactions.any?(&:paid?)
  end

  def reversed?
    transactions.any?(&:reversed?)
  end

  def success?
    order.present? && error_code == '0'
  end
end
