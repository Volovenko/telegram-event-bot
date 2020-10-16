class AddStepToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :step, :string
  end
end
