Spree::Shipment.class_eval do

  scope :delivered, -> { with_state(:delivered) }
  scope :arrangement, -> { with_state(:arrangement) }

  has_one :pickup_address, :class_name => 'Spree::PickupAddress'

  state_machines.clear if respond_to?(:state_machines)

  # shipment state machine (see http://github.com/pluginaweek/state_machine/tree/master for details)
  state_machine initial: :pending, use_transactions: false do

    event :arrange do
      transition :from => :pending, :to => :arrangement
    end

    event :ready do
      transition from: :arrangement, to: :ready, if: lambda { |shipment|
        # Fix for #2040
        shipment.determine_state(shipment.order) == 'ready'
      }
    end

    event :pend do
      transition to: :pending, from: [:ready, :arrangement]
    end

    event :deliver do
      transition from: :ready, to: :delivering, if: lambda { |shipment|
        shipment.shipping_method.id == shipment.courier_shipment_method_id
      }
    end

    event :ship do
      # самовывоз
      transition from: :ready, to: :shipped, if: lambda { |shipment|
        shipment.shipping_method.id != shipment.courier_shipment_method_id
      }
      # курьер
      transition from: :delivering, to: :shipped, if: lambda { |shipment|
        shipment.shipping_method.id == shipment.courier_shipment_method_id
      }
    end
    after_transition to: :shipped, do: :after_ship

    event :cancel do
      transition to: :canceled, from: [:pending, :ready, :arrangement]
    end
    after_transition to: :canceled, do: :after_cancel

    event :resume do
      transition from: :canceled, to: :ready, if: lambda { |shipment|
        shipment.determine_state(shipment.order) == :ready
      }
      transition from: :canceled, to: :arrangement, if: lambda { |shipment|
        shipment.determine_state(shipment.order) == :arrangement
      }
      transition from: :canceled, to: :pending
    end
    after_transition from: :canceled, to: [:pending, :ready, :arrangement], do: :after_resume

    after_transition do |shipment, transition|
      shipment.state_changes.create!(
          previous_state: transition.from,
          next_state:     transition.to,
          name:           'shipment',
      )
    end
  end

  def determine_state(order)
    # use state machine
    return state
  end

  def next_state
    state_paths.to_states.first
  end

  def courier_shipment_method_id
    method = Spree::ShippingMethod.find_by_admin_name 'courier'
    if method.nil?
      nil
    else
      method.id
    end
  end

end