class Portmone::Responses::OrderStatus < Portmone::Responses::BaseResponse
  %i(bill_date
     pay_date
     pay_order_date
     shop_bill_id
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

  def bill_amount
    if order.status == 'RETURN'
      transactions.select { |t| t.status == 'PAYED' || t.status == 'RETURN' }
                  .map { |t| t.bill_amount }
                  .inject(:+)
    else
      order.bill_amount
    end
  end

  def success?
    order.present? && error_code == '0'
  end
end
