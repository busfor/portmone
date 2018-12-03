class Portmone::Responses::BaseResponse
  attr_reader :response
  attr_reader :xml_data

  def initialize(faraday_response, currency:, timezone:)
    @response = faraday_response
    @xml_data = MultiXml.parse(@response.body)
    @currency = currency
    @timezone = timezone
  end

  def http_status
    response.status
  end
end
