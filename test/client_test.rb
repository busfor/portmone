# frozen_string_literal: true

require 'test_helper'

describe Portmone::Client do
  before(:each) do
    @client = Portmone::Client.new(
      payee_id: '16336',
      locale: 'ru',
      login: 'SHP_BUSFOR2',
      password: '11111111',
    )
  end

  describe 'generate_url' do
    it "returnes valid response" do
      VCR.use_cassette('generate_url') do
        response = @client.generate_url(
          shop_order_number: 'payment_id-1',
          amount: Money.new(5000, 'UAH'),
          description: 'Киев-Львов',
          return_url: 'httsp://example.com',
          locale: 'ru'
        )

        assert response.success?
        assert_equal 'https://www.portmone.com.ua/r3/pg/gdl55qpbexsk40w4wwk00skcw8sg0cg?is=32366a2feb29d2d06783c8e25f0917441e2b884d5c0c3d2c8e2282ec348d933d549d70ef', response.location
      end
    end
  end

  describe 'order_status' do
    it "returnes valid response if success" do
      VCR.use_cassette('order_status_success') do
        response = @client.order_status('payment_id-1')
        assert_equal '432722352', response.shop_bill_id
        assert_equal 'Киев-Львов', response.description
        assert_equal Date.parse('21.11.2018'), response.bill_date
        assert_equal Time.new(2018, 11, 21, 10, 54, 42,'+02:00'), response.pay_date
        assert_nil response.pay_order_date
        assert_equal Money.new(5000, 'UAH'), response.bill_amount
        assert_equal 'TESTPM', response.auth_code
        assert_equal 'REJECTED', response.status
        assert_equal '0', response.error_code
        assert_nil response.error_message
      end
    end

    it "returnes valid response if order not found" do
      VCR.use_cassette('order_status_error') do
        response = @client.order_status('dummy')
        refute response.success?
        assert_nil response.error_code # no error from Portmone :( no order too
      end
    end
  end

  describe 'void' do
    it "returnes valid response if success" do
      VCR.use_cassette('void_success') do
        response = @client.void(432781508)
        assert_equal '432781508', response.shop_bill_id
        assert_equal 'Киев-Львов', response.description
        assert_equal Date.parse('21.11.2018'), response.bill_date
        assert_equal Time.new(2018, 11, 21, 0, 0, 0,'+02:00'), response.pay_date
        assert_nil response.pay_order_date
        assert_equal Money.new(5000, 'UAH'), response.bill_amount
        assert_equal 'TESTPM', response.auth_code
        assert_equal 'REJECTED', response.status
        assert_equal '0', response.error_code
        assert_equal '', response.error_message
      end
    end

    it "returnes valid response if order cannot be voided" do
      VCR.use_cassette('void_error_1') do
        response = @client.void(432781508) # trying to void same order again
        refute response.success?
        assert_equal '6', response.error_code
        assert_equal 'Счет уже ранее был отменен.', response.error_message
      end

      VCR.use_cassette('void_error_2') do
        response = @client.void(99999) # trying to void same order again
        refute response.success?
        assert_equal '6', response.error_code
        assert_equal 'Ошибка при выполнении отмены блокировки средств по счету [SHOP_BILL_ID = 99999]. ORA-20001: Заказ с указанным ID не найден. [ID=99999]', response.error_message
      end
    end
  end

  describe 'charge' do
    it "returnes valid response if success" do
      VCR.use_cassette('charge_success') do
        response = @client.charge(432783653, Money.new(5000, 'UAH'))
        assert_equal '432783653', response.shop_bill_id
        assert_equal 'Киев-Львов', response.description
        assert_equal Date.parse('21.11.2018'), response.bill_date
        assert_equal Time.new(2018, 11, 21, 0, 0, 0,'+02:00'), response.pay_date
        assert_nil response.pay_order_date
        assert_equal Money.new(5000, 'UAH'), response.bill_amount
        assert_equal 'TESTPM', response.auth_code
        assert_equal 'PAYED', response.status
        assert_equal '0', response.error_code
        assert_equal '', response.error_message
      end
    end

    it "returnes valid response if order cannot be charged" do
      VCR.use_cassette('charge_error') do
        response = @client.charge(432783653, Money.new(5000, 'UAH'))
        refute response.success?
        assert_equal '5', response.error_code
        assert_equal 'По данному счету не допускается выполнение подтверждения блокировки средств. [статус=REJECTED]', response.error_message
      end
    end
  end
end
