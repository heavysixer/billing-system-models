class CreditCard < ActiveRecord::Base
  belongs_to :account
  has_many   :charges

  validates_presence_of :number
  validates_presence_of :month
  validates_presence_of :year
  validates_presence_of :cvv
  validates_presence_of :first_name
  validates_presence_of :last_name

  private

  def charge(amount)
    if amount.nil?
      return nil
    end

    if amount.to_i <= 0
      return nil
    end

    credit_card = ActiveMerchant::Billing::CreditCard.new(
      :number => number,
      :month  => month,
      :year   => year,
      :first_name => first_name,
      :last_name  => last_name,
      :verification_value => cvv
    )

    charge_rec = charges.create(:date   => Date.today.strftime("%Y-%m-%d"),
                                :amount => amount)

    # Convert dollars to cents
    amount = (BigDecimal(amount.to_s) * 100).to_i

    gateway_response = nil
    if charge_rec.new_record? == false
      gateway_response = $GATEWAY.purchase(amount,
                                           credit_card,
                                           :ip => '127.0.0.1',
                                           :billing_address => nil)

      charge_rec.gateway_response = gateway_response
      charge_rec.save
    end

    return gateway_response
  end
end
