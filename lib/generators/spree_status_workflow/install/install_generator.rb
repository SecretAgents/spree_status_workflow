module SpreeStatusWorkflow
  module Generators
    class InstallGenerator < Rails::Generators::Base

      class_option :auto_run_migrations, :type => :boolean, :default => false
      source_root File.expand_path("../templates", __FILE__)

      def add_stylesheets
	      copy_file File.expand_path("../../templates/spree_status_workflow.css", __FILE__), 'app/assets/stylesheets/admin/spree_status_workflow.css'

        #inject_into_file 'app/assets/stylesheets/admin/all.css', " *= require admin/spree_status_workflow\n", :before => /\*\//, :verbose => true
      end

      def add_migrations
        run 'bundle exec rake railties:install:migrations FROM=spree_status_workflow'
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

