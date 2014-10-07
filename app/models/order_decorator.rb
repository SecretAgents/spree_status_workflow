Spree::Order.class_eval do

  checkout_flow do
    remove_checkout_step :confirm

    go_to_state :express
    go_to_state :address
    go_to_state :delivery
    go_to_state :payment, if: ->(order) {
                                    # если заказ с телефона или быстрый заказ
      if order.payment_method.nil? || order.order_type == 1 || order.order_type == 3
        false
      else
        order.payment_method.method_type != 'cash_on_delivery'
      end
    }
    #go_to_state :confirm, if: ->(order) { order.confirmation_required? }
    go_to_state :complete

    remove_transition from: :delivery, to: :confirm
    remove_transition from: :payment, to: :confirm
    remove_transition from: :address, to: :confirm
  end

  # state machine for status
  state_machine :status, :initial => :cart do
    event :change_status do
      transition from: :cart, to: :ordering, if: lambda { |order|
        order.state == 'delivery' && order.order_type == 0 #from site
      }
      transition from: :cart, to: :issued, if: lambda { |order|
        order.order_type == 1 #from phone
      }
      transition from: :ordering, to: :issued, if: lambda { |order|
        order.state == 'complete' and (order.payment_method.nil? or order.payment_method.method_type == 'cash_on_delivery')
      }
      transition from: :ordering, to: :payment, if: lambda { |order|
        order.state == 'payment'
      }
      transition from: :payment, to: :paid, if: lambda { |order|
        order.payment_method.method_type != 'cash_on_delivery' and
            order.payment_state == 'completed'
      }

      transition from: :paid, to: :issued, if: lambda { |order|
        order.payment_state == 'completed'
      }

      transition from: :issued, to: :arrangement, if: lambda { |order|
        order.shipment_state == 'arrangement' and order.payment_state != 'invoice'
      }
      transition from: :arrangement, to: :ready, if: lambda { |order|
        order.shipment_state == 'ready'
      }

      transition from: :ready, to: :delivered, if: lambda { |order|
        order.shipment_state == 'delivered'
      }
      transition from: any, to: :shipped, if: lambda { |order|
        order.shipment_state == 'shipped'
      }

      transition from: any, to: :canceled, if: lambda { |order|
        order.state == 'canceled'
      }
      transition from: :canceled, to: :payment, if: lambda { |order|
        order.payment_state == 'invoice'
      }
      transition from: :canceled, to: :arrangement, if: lambda { |order|
        order.payment_state != 'invoice'
      }

    end
  end

  def payment_method
    unless self[:id].nil?
      payment = Spree::Payment.where(:order_id => self[:id]).first
      if payment.nil?
        nil
      else
        payment_method = Spree::PaymentMethod.where(:id => payment.payment_method_id).first
        return payment_method
      end
    end
  end

  def pending_payments
    payments.select(&:invoice?) + payments.select(&:credit?)
  end

  def paid?
    payment_state == 'credit' || payment_state == 'completed'
  end

  def process_payments!
    if pending_payments.empty?
      raise Spree::Core::GatewayError.new Spree.t(:no_pending_payments)
    else
      pending_payments.each do |payment|
        break if payment_total >= total

        payment.process!

        if payment.completed?
          self.payment_total += payment.amount
        end
      end
    end
  rescue Core::GatewayError => e
    result = !!Spree::Config[:allow_checkout_on_gateway_error]
    errors.add(:base, e.message) and return result
  end

  def order_type_string
    case self.order_type
      when 1
        return 'С телефона'
      else
        return 'С сайта'
    end
  end

  def allow_cancel?
    state != 'canceled' and state != 'shipped'
  end

  def after_cancel
    shipments.each { |shipment| shipment.cancel! }
    #payments.completed.each { |payment| payment.credit! }

    # Снижаем популярность товара, если заказ отменен
    line_items.each do |line_item|
      line_item.product.popularity -= line_item.quantity
      line_item.product.popularity = 0 if line_item.product.popularity < 0
      line_item.product.save
    end

    send_cancel_email
    self.update_column(:payment_state, 'void') unless shipped?
    self.update_column(:status, 'canceled')
  end

  def after_resume
    shipments.each { |shipment| shipment.resume! }
    consider_risk

    if payments.first.nil?
      self.payment_state = 'none'
    else
      self.payment_state = payments.first.state
    end

    if self.status == 'canceled'
      if self.state_changes.last(2).count >= 2 and self.state_changes.last(2)[0].previous_state == 'cart'
        self.update_column(:status, 'ordering')
      end
    end
  end

  def ensure_line_items_present
    true
  end

  def finalize_with_popularity!
    finalize_without_popularity!
    # Увеличиваем популярность товара, когда его купили
    line_items.each do |line_item|
      line_item.product.popularity += line_item.quantity
      line_item.product.save
    end
  end
  alias_method_chain :finalize!, :popularity

end