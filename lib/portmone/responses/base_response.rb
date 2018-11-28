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

  def transactions
    @transactions ||= begin
      data = @xml_data.dig('portmoneresult', 'orders', 'order') || @xml_data.dig('portmoneresult', 'order') || {}
      data = [data] unless data.is_a?(Array) # cannot use Array() on Hash
      data.map do |h|
        Portmone::Transaction.new(h.merge(timezone: @timezone, currency: @currency))
      end
    end
  end

  def order
    transactions && transactions.last
  end
end
