class Portmone::Responses::Finish3DS
  attr_reader :response

  def initialize(faraday_response, currency:, timezone:)
    @response = faraday_response
    @currency = currency
    @timezone = timezone
  end

  def http_status
    response.status
  end

  def success?
    http_status == 204
  end
end
