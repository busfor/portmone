class Portmone::Responses::MobilePay
  SUCCESS_STATUS = 'PAYED'.freeze
  CREATED_STATUS = 'CREATED'.freeze

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

  def created?
    @response_body['result']['status'] == CREATED_STATUS
  end

  def error_code
    @response_body['result']['errorCode']
  end

  def error_description
    @response_body['result']['error']
  end

  def required_3ds?
    @response_body['result']['status'] == CREATED_STATUS &&
      @response_body['result']['isNeed3DS']
  end

  def acs_url
    @response_body['result']['actionMPI'] if required_3ds?
  end

  def md
    @response_body['result']['md'] if required_3ds?
  end

  def pa_req
    @response_body['result']['pareq'] if required_3ds?
  end
end
