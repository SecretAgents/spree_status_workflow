module SpreeStatusWorkflow
  module Generators
    class InstallGenerator < Rails::Generators::Base

      class_option :auto_run_migrations, :type => :boolean, :default => false
      source_root File.expand_path("../templates", __FILE__)

      def add_settings
        config_string = <<EOF
  if ActiveRecord::Base.connection.tables.include?('spree_countries')
    unless Spree::Country.find_by_iso3('RUS').nil?
      config.default_country_id = Spree::Country.find_by_iso3('RUS').id
    end
  end
  config.mails_from = Spree::Store.current[:mail_from_address].split(',').first
  config.address_requires_state = false
  config.track_inventory_levels = false
  config.always_put_site_name_in_title = false
  config.currency = 'RUB'
  config.max_level_in_taxons_menu = 15
  config.allow_ssl_in_production = false
  config.allow_ssl_in_staging = false
EOF
        init_string = <<EOF
Spree::Auth::Config[:registration_step] = false
Spree::Image.attachment_definitions[:attachment][:url] = '/spree/products/:id_partition/:style/:basename.:extension'
Spree::Image.attachment_definitions[:attachment][:path] = ':rails_root/public/spree/products/:id_partition/:style/:basename.:extension'

Money::Currency.register(
    priority: 1,
    iso_code: 'RUB',
    name: 'Russian Ruble',
    symbol: 'руб.'.html_safe,
    alternate_symbols: ['р', 'RUB'],
    subunit: 'copeck',
    subunit_to_unit: 100,
    symbol_first: false,
    html_entity: '',
    decimal_mark: '.',
    thousands_separator: ' ',
    iso_numeric: '810'
)

config = Rails.application.config
config.after_initialize do
  config.spree.calculators.shipping_methods << Spree::Calculator::Shipping::CourierCalculator
  config.spree.calculators.shipping_methods << Spree::Calculator::Shipping::PickupCalculator
  config.spree.calculators.shipping_methods << Spree::Calculator::Shipping::PerKilometer
end
EOF
        inject_into_file('vendor/assets/stylesheets/spree/backend/all.css', config_string, :after => /Spree\.config do |config|/, :verbose => true)
        append_file 'config/initializers/spree.rb', init_string, :verbose => false
      end

      def add_stylesheets
	      copy_file File.expand_path("../../templates/spree_status_workflow.css", __FILE__), 'vendor/assets/stylesheets/spree/backend/spree_status_workflow.css'

        # inject_into_file 'vendor/assets/stylesheets/spree/backend/all.css', " *= require spree_status_workflow\n", :before => /\*\//, :verbose => true
      end

      def add_migrations
        run 'bundle exec rake railties:install:migrations FROM=spree_status_workflow'
      end

      def add_seeds
        append_file 'config/initializers/spree.rb', 'SpreeStatusWorkflow::Engine.load_seed if defined?(SpreeStatusWorkflow)', :verbose => false
      end

      def run_migrations
        run_migrations = options[:auto_run_migrations] || ['', 'y', 'Y'].include?(ask 'Would you like to run the migrations now? [Y/n]')
        if run_migrations
          run 'bundle exec rake db:migrate'
        else
          puts 'Skipping rake db:migrate, don\'t forget to run it!'
        end
      end

    end
  end
end

