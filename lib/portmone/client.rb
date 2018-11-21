module Portmone
  class Client
    BASE_URL = 'https://www.portmone.com.ua/gateway/'.freeze

    def initialize(payee_id:, login:, password:, locale:, debug: false)
      @payee_id = payee_id
      @login = login
      @password = password
      @locale = locale
      @logger = debug ? Logger.new(STDOUT) : Logger.new(File.open(File::NULL, 'w'))
    end

    def generate_url(shop_order_number:, amount:, route_name:, callback_url:, locale:, authorize_only: true)
      method nil
      response Portmone::Responses::GenerateURL

      send_request(
        shop_order_number: shop_order_number,
        bill_amount: format_amount(amount),
        description: route_name,
        success_url: callback_url,
        failure_url: callback_url,
        encoding: 'utf-8',
        preauth_flag: authorize_only ? 'Y' : 'N'
      )
    end

    def order_status(order_id)
      response Portmone::Responses::ReportOrderStatus
      generic_report(order_id: order_id)
    end

    def void(order_id)
      response Portmone::Responses::OrderStatus
      generic_preauth_update(order_id: order_id, action: 'reject')
    end

    def charge(order_id, amount)
      response Portmone::Responses::OrderStatus
      generic_preauth_update(order_id: order_id, action: 'set_paid', amount: amount)
    end

    def refund(order_id, amount:)
      method 'return'
      response Portmone::Responses::OrderStatus
      send_signed_request(
        shop_bill_id: order_id,
        return_amount: format_amount(amount),
      )
    end

  private

    # может возвращать как отдельный заказ по id, так и все заказы с опр. статусом или в опр. временном диапазоне
    def generic_report(order_id: nil, status: nil, start_date: nil, end_date: nil)
      method 'result'

      send_signed_request(
        shop_order_number: order_id,
        status: status,
        start_date: start_date,
        end_date: end_date,
      )
    end

    def generic_preauth_update(order_id:, action:, amount: nil)
      method 'preauth'

      send_signed_request(
        shop_bill_id: order_id,
        action: action,
        postauth_amount: format_amount(amount),
      )
    end

    def format_date(date)
      date.strftime("%d.%m.%Y")
    end

    def format_amount(amount)
      amount.to_f
    end

    def method(name)
      @method = name
    end

    def response(response_klass)
      @response_klass = response_klass
    end

    def send_signed_request(**data)
      send_request(data.merge(
        login: @login,
        password: @password,
      ))
    end

    def send_request(**data)
      response = http_client.post(BASE_URL) do |req|
        req.body = data.merge(
          method: @method,
          payee_id: @payee_id,
          lang: @locale,
        ).delete_if { |_, v| v.nil? }
      end

      @response_klass.new(response)
    end

    def http_client
      @http_client ||= Faraday.new do |builder|
        builder.request :url_encoded
        builder.response :logger, @logger, bodies: true
        builder.adapter Faraday.default_adapter
      end
    end
  end
end
