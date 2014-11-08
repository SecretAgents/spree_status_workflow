Spree::Shipment.class_eval do

  EVENTS_PRIORITY = {
      :arrange => :arrangement,
      :ready => :ready,
      :deliver => :delivering,
      :ship => :shipped,
      :pend => :pending,
      :cancel => :canceled
  }

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
      transition from: :arrangement, to: :ready
      # if: lambda { |shipment|
      #   # Fix for #2040
      #   shipment.determine_state(shipment.order) == 'ready'
      # }
    end

    event :pend do
      transition to: :pending, from: [:ready, :arrangement]
    end

    event :deliver do
      transition from: :ready, to: :delivering, if: lambda { |shipment|
        !Spree::Shipment.non_delivering_methods.include?(shipment.shipping_method.id)
      }
    end

    event :ship do
      # самовывоз
      transition from: :ready, to: :shipped, if: lambda { |shipment|
        Spree::Shipment.non_delivering_methods.include?(shipment.shipping_method.id)
      }
      # курьер
      transition from: :delivering, to: :shipped, if: lambda { |shipment|
        !Spree::Shipment.non_delivering_methods.include?(shipment.shipping_method.id)
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

    before_transition to: :arrangement, do: :defore_arrange
    before_transition to: :ready, do: :defore_ready
    before_transition to: :delivering, do: :defore_deliver
    before_transition to: :shipped, do: :defore_ship

    after_transition do |shipment, transition|
      shipment.state_changes.create!(
          previous_state: transition.from,
          next_state:     transition.to,
          name:           'shipment',
      )
    end
  end

  def defore_arrange
    self.order.arrange
  end

  def defore_ready
    self.order.ready
  end

  def defore_deliver
    self.order.deliver
  end

  def defore_ship
    self.order.ship
  end

  def next!
    send "#{next_event}!"
  end

  def send_shipped_email_with_check
    send_shipped_email_without_check unless self.order.email.blank?
  end
  alias_method_chain :send_shipped_email, :check

  def determine_state(order)
    # use state machine
    return state
  end

  def next_event
    available_events.first
  end

  def next_state
    available_states.first
  end

  def available_events
    events = []
    EVENTS_PRIORITY.each do |event, state|
      events << event if send("can_#{event}?")
    end
    events
  end

  def available_states
    states = []
    EVENTS_PRIORITY.each do |event, state|
      states << state if send("can_#{event}?")
    end
    states
  end

  def self.non_delivering_methods
    [pickup_shipment_method_id, pickup_discount_shipment_method_id]
  end

  def self.courier_shipment_method_id
    shipment_method_id('inside_mkad')
  end

  def self.outside_mkad_shipment_method_id
    shipment_method_id('outside_mkad')
  end

  def self.tk_shipment_method_id
    shipment_method_id('tk')
  end

  def self.pickup_discount_shipment_method_id
    shipment_method_id('pickup_discount')
  end

  def self.pickup_shipment_method_id
    shipment_method_id('pickup')
  end

  def self.default_shipment_method_id
    shipment_method_id('default_shipping')
  end

  def self.default_pickup_shipment_method_id
    shipment_method_id('default_shipping')
  end

  private

    def self.shipment_method_id(key)
      method = Spree::ShippingMethod.where(:admin_name => key).first
      if method.nil?
        nil
      else
        method.id
      end
    end

end