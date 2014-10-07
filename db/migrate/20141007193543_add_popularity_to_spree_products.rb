class AddPopularityToSpreeProducts < ActiveRecord::Migration
  def change
    add_column :spree_products, :popularity, :integer, :default => 0
  end
end