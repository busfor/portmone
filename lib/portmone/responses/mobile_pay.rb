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
    result['status'] == SUCCESS_STATUS
  end

  def created?
    result['status'] == CREATED_STATUS
  end

  def error_code
    result['errorCode']
  end

  def error_description
    result['error']
  end

  def required_3ds?
    created? && result['isNeed3DS'] == 'Y'
  end

  def acs_url
    result['actionMPI'] if required_3ds?
  end

  def md
    result['md'] if required_3ds?
  end

  def pa_req
    result['pareq'] if required_3ds?
  end

  def shop_bill_id
    result['shopBillId']
  end

  private

  def result
    @result ||= @response_body['result']
  end
end
