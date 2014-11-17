Spree::Order.class_eval do

  TYPES = {
    0 => nil,
    1 => :phone,
    2 => :site,
    3 => :express
  }

  # Remove the requirement on :phone being present.
  _validators.reject!{ |key, _| [:email].include?(key)  }

  _validate_callbacks.each do |callback|
    callback.raw_filter.attributes.delete :email if callback.raw_filter.is_a?(ActiveModel::Validations::PresenceValidator)
  end

  checkout_flow do
    remove_checkout_step :confirm
    remove_checkout_step :address

    go_to_state :delivery
    go_to_state :payment, if: ->(order) {
      # если заказ с телефона или быстрый заказ
      if order.payment_method.nil? || order.type == :phone || order.type == :express
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

  # To avoid a ton of warnings when the state machine is re-defined
  StateMachine::Machine.ignore_method_conflicts = true
  # To avoid multiple occurrences of the same transition being defined
  # On first definition, state_machines will not be defined
  state_machines.clear if respond_to?(:state_machines)
  state_machine :state, :initial => :cart, :use_transactions => false, :action => :save_state do
    # klass.next_event_transitions.each { |t| transition(t.merge(:on => :next)) }

    # Persist the state on the order
    after_transition do |order, transition|
      order.state = order.state
      order.state_changes.create(
          previous_state: transition.from,
          next_state:     transition.to,
          name:           'order',
          user_id:        order.user_id
      )
      order.save
    end

    event :cart do
      transition :to => :cart, :from => :ordering, :if => :express?
    end

    event :cancel do
      transition :to => :canceled, :from => [:complete, :arrangement, :ready], :if => :allow_cancel?
    end

    event :resume do
      transition :from => :canceled, :to => :complete
    end

    event :authorize_return do
      transition :to => :awaiting_return, :from => any - [:cart, :ordering, :complete, :payment, :canceled, :awaiting_return, :returned], :if => :need_return?
    end

    event :return do
      transition :to => :returned, :from => :awaiting_return, :unless => :awaiting_returns?
    end

    event :order do
      transition :to => :ordering, :from => :cart, :unless => :express?
    end

    event :complete do
      transition :to => :complete, :from => :cart, :if => :express?
      transition :to => :complete, :from => :ordering, :unless => :express?
    end

    event :arrange do
      transition :to => :arrangement, :from => [:complete, :paid]
    end

    event :payment do
      transition :to => :payment, :from => :complete, :if => :need_payment?
    end

    event :pay do
      transition :to => :paid, :from => :payment
    end

    event :ready do
      transition :to => :ready, :from => :arrangement
    end

    event :deliver do
      transition :to => :delivering, :from => :ready
    end

    event :ship do
      transition :to => :shipped, :from => [:delivering, :ready]
    end

    if states[:payment]
      before_transition :to => :complete do |order|
        if order.payment_required? && order.payments.valid.empty?
          order.errors.add(:base, Spree.t(:no_payment_found))
          false
        elsif order.payment_required?
          order.process_payments!
        end
      end
    end

    before_transition :from => :cart, :do => :ensure_line_items_present

    if states[:payment]
      before_transition :to => :payment, :do => :set_shipments_cost
      before_transition :to => :payment, :do => :create_tax_charge!
    end

    if states[:ordering]
      before_transition :to => :ordering, :do => :create_proposed_shipments
      before_transition :to => :ordering, :do => :ensure_available_shipping_rates
      before_transition :to => :ordering, :do => :set_shipments_cost
      before_transition :to => :ordering, :do => :assign_default_addresses!
      before_transition :from => :ordering, :do => :apply_free_shipping_promotions
      before_transition :from => :ordering, :do => :create_tax_charge!
      before_transition :from => :ordering, :do => :persist_user_address!
    end

    after_transition :to => :complete, :do => :finalize!
    after_transition :from => :canceled, :do => :after_resume
    after_transition :to => :canceled, :do => :after_cancel

    after_transition :from => any - :cart, :to => any - :complete do |order|
      order.update_totals
      order.persist_totals
    end
  end

  def self.shipped
    where(status: 'shipped')
  end

  def payment_state
    return payments.first.state if payments.any?
    self.attributes[:payment_state]
  end

  def self.get_type_id(symbol)
    TYPES.key symbol
  end

  def self.get_type_symbol(key)
    TYPES[key]
  end

  def type
    TYPES[order_type]
  end

  def set_type(symbol)
    self.order_type = Spree::Order.get_type_id symbol
  end

  def address?
    !!bill_address
  end

  def express?
    type == :express
  end

  def need_payment?
    !(payment_method.nil? or payment_method.method_type == 'cash_on_delivery')
  end

  def invoiced?
    payment_state == 'invoice'
  end

  def need_return?
    payment_completed? or shipped?
  end

  def allow_cancel?
    !need_return?
  end

  def payment_method
    return nil if id.nil?
    payment = Spree::Payment.where(:order_id => id).first
    return nil if payment.nil?
    Spree::PaymentMethod.where(:id => payment.payment_method_id).first
  end

  def pending_payments
    payments.select(&:invoice?) + payments.select(&:credit?)
  end

  def payment_completed?
    payment_state == 'completed'
  end

  def paid?
    payment_state == 'credit' || payment_state == 'completed'
  end

  def order_type_string
    return 'С телефона' if type == :phone
    return 'Быстрый заказ' if type == :express
    return 'С сайта'
  end

  def add_payment_if_needed!
    if self.payments.empty?
      self.payments.create!(
          :amount => self.total,
          :state => :credit,
          :payment_method => Spree::PaymentMethod.where(
              :type => 'Spree::CashOnDelivery::PaymentMethod',
              :environment => Rails.env
          ).first
      )
      self.payment_state = self.payments.first.state
    end
  end

  def deliver_order_confirmation_email_with_check
    deliver_order_confirmation_email_without_check unless self.email.blank?
  end
  alias_method_chain :deliver_order_confirmation_email, :check

  def send_cancel_email_with_check
    send_cancel_email_without_check unless self.email.blank?
  end
  alias_method_chain :send_cancel_email, :check

  def assign_by_phone(phone)
    user = Spree::User.find_by_phone phone
    address = Spree::Address.default user
    address.phone = phone
    password = Spree::User.generate_password
    user ||= Spree::User.new(
        bill_address: address,
        password: password
    )
    user.phone = phone if user.phone.blank?
    user.save
    unless user.nil?
      # TODO: Отправить пароль по email или в sms

      self.email = user.email unless user.email.nil?
      self.user_id = user.id
      self.bill_address = user.bill_address
      self.bill_address ||= address
      self.ship_address ||= address
      self.use_billing = true
    end
    save
  end

  def after_cancel
    shipments.each { |shipment| shipment.cancel! unless shipment.canceled? }
    #payments.completed.each { |payment| payment.credit! }

    # Снижаем популярность товара, если заказ отменен
    line_items.each do |line_item|
      line_item.product.popularity -= line_item.quantity
      line_item.product.popularity = 0 if line_item.product.popularity < 0
      line_item.product.save
    end

    send_cancel_email
    self.update_column(:payment_state, 'void') unless shipped?
    self.update_column(:shipment_state, 'canceled') unless shipped?
    self.save
  end

  def after_resume
    shipments.each { |shipment| shipment.resume! if shipment.canceled? }
    consider_risk

    if payments.first.nil?
      self.payment_state = 'none'
    else
      self.payment_state = payments.first.state
    end

    if shipments.first.nil?
      self.shipment_state = 'none'
    else
      self.shipment_state = shipments.first.state
    end
    self.save
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