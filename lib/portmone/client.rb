module Portmone
  class Error < StandardError; end

  class Client
    API_URL = 'https://www.portmone.com.ua/gateway/'.freeze
    MOBILE_API_URL = 'https://www.portmone.com.ua/r3/api/gateway'.freeze

    def initialize(payee_id:,
                   login:,
                   password:,
                   locale:,
                   currency:,
                   exp_time: nil,
                   timezone: 'Europe/Kiev',
                   logger: nil)
      @payee_id = payee_id
      @login = login
      @password = password
      @locale = locale
      @currency = currency
      @timezone = timezone
      @logger = logger
      @exp_time = exp_time
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
        preauth_flag: authorize_only ? 'Y' : 'N',
        exp_time: @exp_time
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

    def google_pay(token:, amount:, order_id:, currency:)
      google_pay_params = {
        gPayToken: token,
      }
      mobile_pay('GPay', google_pay_params, amount: amount, order_id: order_id, currency: currency)
    end

    def apple_pay(token:, amount:, order_id:, currency:, merchant_name:)
      apple_pay_params = {
        aPayMerchantName: merchant_name,
        aPayToken: token,
      }
      mobile_pay('APay', apple_pay_params, amount: amount, order_id: order_id, currency: currency)
    end

    private

    def mobile_pay(payment_method, payment_system_params, amount:, order_id:, currency:)
      order_params = {
        billAmount: amount,
        shopOrderNumber: order_id,
        billCurrency: currency,
      }

      data = payment_system_params
        .merge(order_params)
        .merge(base_params)
        .keep_if { |_, v| v.present? }
      params = { params: { data: data }, method: payment_method }

      make_json_request(MOBILE_API_URL, params, Portmone::Responses::MobilePayResponse)
    end

    def base_params
      {
        login: @login,
        password: @password,
        payeeId: @payee_id,
      }
    end

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
      payload = compact(data.merge(mandatory_params))

      response = http_client.post(API_URL) do |req|
        req.body = payload
      end

      response_class.new(response, currency: @currency, timezone: @timezone)
    end

    def make_json_request(url, params, response_class)
      response = Faraday.new(url).post do |request|
        request.headers['Content-Type'] = 'application/json'
        request.body = params.to_json
      end
      response_class.new(response, currency: @currency, timezone: @timezone)
    end

    def mandatory_params
      { payee_id: @payee_id, lang: @locale }
    end

    def compact(**params)
      params.delete_if { |_, v| v.nil? }
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
