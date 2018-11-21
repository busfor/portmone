class Portmone::Responses::ReportOrderStatus < Portmone::Responses::OrderStatus

private

  def order
    @xml_data.dig('portmoneresult', 'orders', 'order')
  end
end
