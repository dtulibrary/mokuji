class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :api_key
      t.string :sn
      t.string :ln
      t.timestamps
    end
  end
end
