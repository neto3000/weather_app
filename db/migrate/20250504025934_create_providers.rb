class CreateProviders < ActiveRecord::Migration[8.0]
  def change
    create_table :providers do |t|
      t.string :name
      t.string :base_url

      t.timestamps
    end
  end
end
