class CreateWeatherReadings < ActiveRecord::Migration[8.0]
  def change
    create_table :weather_readings do |t|
      t.references :provider, null: false, foreign_key: true
      t.float   :lat
      t.float   :lon
      t.string  :city
      t.string  :state
      t.string :country
      t.string :zip_code
      t.text    :payload, null: false, default: '{}'
      t.datetime :fetched_at,  null: false

      t.timestamps
    end
  end
end
