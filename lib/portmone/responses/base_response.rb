class Portmone::Responses::BaseResponse
  attr_reader :response
  attr_reader :xml_data

  def initialize(faraday_response)
    @response = faraday_response
    @xml_data = MultiXml.parse(@response.body)
  end

  def status
    response.status
  end
end
