module Portmone
  class Error < StandardError; end

  class Client
    BASE_URL = 'https://www.portmone.com.ua/gateway/'.freeze

    def initialize(payee_id:,
                   login:,
                   password:,
                   locale:,
                   currency:,
                   timezone: 'Europe/Kiev',
                   logger: nil)
      @payee_id = payee_id
      @login = login
      @password = password
      @locale = locale
      @currency = currency
      @timezone = timezone
      @logger = logger
    end

    def generate_url(shop_order_number:, amount:, description:, success_url:, failure_url:, authorize_only: true)

      send_request(
        response_class: Portmone::Responses::GenerateURL,
        method: nil,
        shop_order_number: shop_order_number,
        bill_amount: format_amount(amount),
        bill_currency: @currency,
        description: description,
        success_url: success_url,
        failure_url: failure_url,
        encoding: 'utf-8',
        preauth_flag: authorize_only ? 'Y' : 'N'
      )
    end

    def order_status(shop_order_number)
      generic_report(shop_order_number: shop_order_number)
    end

    def void(order_id)
      generic_preauth_update(order_id: order_id, action: 'reject')
    end

    def charge(order_id, amount)
      generic_preauth_update(order_id: order_id, action: 'set_paid', amount: amount)
    end

    def refund(order_id, amount:)
      send_signed_request(
        response_class: Portmone::Responses::RefundOrderStatus,
        method: 'return',
        shop_bill_id: order_id,
        return_amount: format_amount(amount),
      )
    end

  private

    # может возвращать как отдельный заказ по id, так и все заказы с опр. статусом или в опр. временном диапазоне
    def generic_report(shop_order_number: nil, status: nil, start_date: nil, end_date: nil)
      send_signed_request(
        response_class: Portmone::Responses::OrderStatus,
        method: 'result',
        shop_order_number: shop_order_number,
        status: status,
        start_date: start_date,
        end_date: end_date,
      )
    end

    def generic_preauth_update(order_id:, action:, amount: nil)
      attrs = {
        method: 'preauth',
        response_class: Portmone::Responses::OrderStatus,
        shop_bill_id: order_id,
        action: action,
      }
      attrs[:postauth_amount] = format_amount(amount) if amount
      send_signed_request(attrs)
    end

    def format_date(date)
      date.strftime("%d.%m.%Y")
    end

    def format_amount(amount)
      raise "Wrong currency! (got #{amount.currency}, expected #{@currency})" unless amount.currency == @currency

      amount.to_f
    end

    def send_signed_request(**data)
      send_request(data.merge(
        login: @login,
        password: @password,
      ))
    end

    def send_request(**data)
      response_class = data.delete(:response_class)
      response = http_client.post(BASE_URL) do |req|
        req.body = data.merge(
          payee_id: @payee_id,
          lang: @locale,
        ).delete_if { |_, v| v.nil? }
      end

      response_class.new(response, currency: @currency, timezone: @timezone)
    end

    def http_client
      @http_client ||= Faraday.new do |builder|
        builder.request :url_encoded
        builder.response :logger, @logger, bodies: true if @logger
        builder.adapter Faraday.default_adapter
      end
    end
  end
end
