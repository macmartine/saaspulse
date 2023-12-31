module ApplicationHelper
  include Helpers::Base

  def current_theme
    :light
  end

  def currency_formatter(value, is_potential = false, is_negative = false)

    if is_potential
      if is_negative
        return "#{down}#{number_to_currency(value.to_i, precision: 0).gsub('-', '')}"
      else
        return "#{up_yellow}#{number_to_currency(value.to_i, precision: 0).gsub('-', '')}"
      end
    end
    op = value.to_i >= 0 ? up : down
    return "#{op}#{number_to_currency(value.to_i, precision: 0).gsub('-', '')}"
  end

  def coupon_string(discount)
    if discount.present?
      "Coupon: #{discount.dig('coupon', 'name')}"
    end
  end

  def up
    "<img src='https://app.saaspulse.io/images/arrow-up-right.png' style='vertical-align: middle; margin-right: 2px'/>"
  end

  def down
    "<img src='https://app.saaspulse.io/images/arrow-down-right.png' style='vertical-align: middle; margin-right: 2px'/>"
  end

  def up_yellow
    "<img src='https://app.saaspulse.io/images/arrow-up-right-yellow.png' style='vertical-align: middle; margin-right: 2px'/>"
  end

  def down_yellow
    "<img src='https://app.saaspulse.io/images/arrow-down-right-yellow.png' style='vertical-align: middle; margin-right: 2px'/>"
  end

  def stripe_icon
    "<img src='https://app.saaspulse.io/images/stripe.png' style='vertical-align: middle; margin-right: 2px'/>"
  end

  def change_class(value, is_potential = false, is_negative = false)
    return '' if value.blank?
    if is_potential
      if is_negative
        return 'red' 
      else
        return 'yellow' 
      end
    end
    if value.is_a?(Integer)
      return value >= 0 ? 'green' : 'red'
    else
      return value.include?('down') ? 'red' : 'green'
    end
  end

  def currency_to_number(currency)
    currency.to_s.gsub(/[$,]/,'').to_f
  end

end
