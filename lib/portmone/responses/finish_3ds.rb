class Portmone::Responses::Finish3DS
  attr_reader :response

  def initialize(faraday_response, currency:, timezone:)
    @response = faraday_response
    @currency = currency
    @timezone = timezone
    @response_body = JSON.parse(@response.body)
  end

  def http_status
    response.status
  end

# Если в ответе получены значения параметров isNeed3DS: "N", errorCode: "0", status: "PAYED" - платеж считать успешным
# Если в ответе получено isNeed3DS: "Y" и заполнены actionMPI, pareq, md, необходимо их обрабатывать и редиректить клиента
# по actionMPI пока не будут получены в ответе is3DS: "N ", errorCode: "0 ", status: “PAYED",
# или status: "REJECTED"- если платеж неуспешный

  def success?
    result['status'] == SUCCESS_STATUS
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
