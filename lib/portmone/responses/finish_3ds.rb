class Portmone::Responses::Finish3DS
  SUCCESS_STATUS = 'PAYED'.freeze

  attr_reader :response

  def initialize(faraday_response, currency:, timezone:)
    @response = faraday_response
    @currency = currency
    @timezone = timezone
    @response_body = JSON.parse(@response.body || {})
  end

  def http_status
    response.status
  end

  def success?
    result['status'] == SUCCESS_STATUS && !required_3ds?
  end

  def error_code
    result['errorCode']
  end

  def error_description
    result['error']
  end

  def required_3ds?
    result['isNeed3DS'] == 'Y'
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

  private

  def result
    @result ||= @response_body['result']
  end
end
