class Portmone::Responses::BaseResponse
  attr_reader :response
  attr_reader :xml_data

  def initialize(faraday_response, currency:)
    @response = faraday_response
    @xml_data = MultiXml.parse(@response.body)
    @currency = currency
  end

  def status
    response.status
  end
end
