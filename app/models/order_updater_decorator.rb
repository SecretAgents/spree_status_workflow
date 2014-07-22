Spree::OrderUpdater.class_eval do

  def update_payment_state
    state_priorities = {
        :invoice => 9,
        :credit => 9,
        :failed => 8,
        :completed => 11,
        :paid => 12,
        :void => 8,
        :processing => 10
    }

    if payments.each.first.nil?
      order.payment_state = nil
    else
      result_state = payments.each.first.state

      payments.each do |payment|
        if state_priorities[payment.state.to_sym] > state_priorities[result_state.to_sym]
          result_state = payment.state
        end
      end

      order.payment_state = result_state
    end

    order.change_status

    order.state_changed('payment')
  end

  def update_shipment_state

    state_priorities = {
      :arrangement => 10,
      :ready => 8,
      :delivered => 9,
      :shipped => 7,
      :canceled => 11
    }

    if order.backordered?
      order.shipment_state = 'backorder'
    else
      shipment_states = shipments.states

      result_state = shipments.states.first
      shipment_states.each do |state|
        if state_priorities[state.to_sym] > state_priorities[result_state.to_sym]
          result_state = state
        end
      end
      order.shipment_state = result_state
      order.change_status
    end
    order.state_changed('shipment')
  end


end
