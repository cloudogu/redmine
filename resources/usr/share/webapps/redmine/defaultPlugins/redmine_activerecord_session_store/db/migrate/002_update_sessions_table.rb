class UpdateSessionsTable < ActiveRecord::Migration[4.2]
  def self.up
    add_column :sessions, :service_ticket, :string
    add_index :sessions, :service_ticket
  end

  def self.down
    remove_index :sessions, :service_ticket
    remove_column :sessions, :service_ticket
  end
end