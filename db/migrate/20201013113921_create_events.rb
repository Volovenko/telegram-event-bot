class CreateEvents < ActiveRecord::Migration[5.0]
  def change
    create_table :events do |t|
      t.string :text
      t.string :date
      t.references :user

      t.timestamps
    end
  end
end
