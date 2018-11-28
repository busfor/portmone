module Portmone
  class Transaction
    attr_reader :data

    def initialize(data)
      @timezone = data.delete(:timezone)
      @currency = data.delete(:currency)
      unless data.is_a?(Hash)
        raise Error, "Wrong data: Hash expected, got #{data.inspect}"
      else
        @data = data
      end
    end

    def bill_date
      Date.parse(data['bill_date'])
    end

    def pay_date
      ActiveSupport::TimeZone[@timezone].parse(data['pay_date'])
    end

    def pay_order_date
      ActiveSupport::TimeZone[@timezone].parse(data['pay_order_date']) rescue nil
    end

    def bill_amount
      Money.from_amount(data['bill_amount'].to_f, @currency)
    end

    %i(shop_bill_id
       shop_order_number
       description
       auth_code
       status
       error_code
       error_message).each do |key|

      define_method(key) do
        data.dig(key.to_s)
      end
    end
  end
end
