Spree::Shipment.class_eval do

  scope :delivered, -> { with_state(:delivered) }
  scope :arrangement, -> { with_state(:arrangement) }

  state_machines.clear

  # shipment state machine (see http://github.com/pluginaweek/state_machine/tree/master for details)
  state_machine initial: :arrangement, use_transactions: false do
    event :ready do

    end

    event :pend do

    end

    event :ship do
      # самовывоз
      transition from: :ready, to: :shipped, if: lambda { |shipment|
        shipment.shipping_method.id == 1
      }
      # курьер
      transition from: :delivered, to: :shipped, if: lambda { |shipment|
        shipment.shipping_method.id == 2
      }
      transition from: :ready, to: :delivered, if: lambda { |shipment|
        shipment.shipping_method.id == 2
      }


      transition from: :arrangement, to: :ready


    end
    after_transition to: :shipped, do: :after_ship

    event :cancel do
      transition to: :canceled, from: [:pending, :ready]
    end
    after_transition to: :canceled, do: :after_cancel

    event :resume do
      transition from: :canceled, to: :ready, if: lambda { |shipment|
        shipment.determine_state(shipment.order) == :ready
      }
      transition from: :canceled, to: :pending, if: lambda { |shipment|
        shipment.determine_state(shipment.order) == :ready
      }
      transition from: :canceled, to: :pending
    end
    after_transition from: :canceled, to: [:pending, :ready], do: :after_resume
  end

  def determine_state(order)
    # use state machine
    return state
  end

  def next_state
    case state
      when 'arrangement'
        return :ready
      when 'ready'
        # самовывоз
        if self.shipping_method.id == 1
          return :shipped
        else
          return :delivered
        end
      when 'delivered'
        return :shipped
      else
        nil
    end
  end

end