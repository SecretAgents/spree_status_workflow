Spree::Payment.class_eval do

  scope :completed, -> { with_state('completed') }
  scope :pending, -> { with_state('pending') }
  scope :failed, -> { with_state('failed') }
  scope :invoice, -> { with_state('invoice') }
  scope :credit, -> { with_state('credit') }
  state_machines.clear

  state_machine :initial => lambda {|payment|
    method_name = Spree::PaymentMethod.find_by_id(payment.payment_method_id)
    if method_name.nil?
      :credit
    else
      case method_name.method_type
        when 'cash_on_delivery'
          :credit
        else
          :invoice
      end
    end

      }  do
    # With card payments, happens before purchase or authorization happens
    event :started_processing do
      transition from: [:invoice, :credit], to: :processing
    end
    # When processing during checkout fails
    event :failure do
      transition from: [:invoice, :credit], to: :failed
    end
    # With card payments this represents authorizing the payment
    event :pend do
      transition from: [:checkout, :processing], to: :pending
    end
    # With card payments this represents completing a purchase or capture transaction
    event :complete do
      transition from: [:processing ], to: :completed
    end
    event :void do
      transition from: [:invoice, :credit, :processing ], to: :void
    end
    # when the card brand isnt supported      transition from: [:processing ], to: :completed

    event :invalidate do
      transition from: [:invoice, :credit ], to: :invalid
    end
  end
#:if => lambda { |payment| payment.payment_method_id == 4}


end