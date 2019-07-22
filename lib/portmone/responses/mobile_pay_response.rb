class Portmone::Responses::MobilePayResponse
  SUCCESS_STATUS = 'PAYED'.freeze

  attr_reader :response

  def initialize(faraday_response, currency:, timezone:)
    @response = faraday_response
    @response_body = JSON.parse(@response.body)
    @currency = currency
    @timezone = timezone
  end

  def http_status
    response.status
  end

  def success?
    @response_body['result']['status'] == SUCCESS_STATUS
  end

  def error_code
    @response_body['result']['errorCode']
  end

  def error_description
    @response_body['result']['error']
  end
end
