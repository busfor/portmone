class Portmone::Responses::RefundOrderStatus < Portmone::Responses::OrderStatus
  def success?
    order.present? && error_code == '0' && order['status'] == 'RETURN'
  end
end
