class Portmone::Responses::GenerateURL < Portmone::Responses::BaseResponse
  def success?
    location.present? && status == 302
  end

  def location
    response.headers['location']
  end
end
