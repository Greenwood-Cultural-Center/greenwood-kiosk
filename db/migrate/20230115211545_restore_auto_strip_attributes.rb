class RestoreAutoStripAttributes < ActiveRecord::Migration[7.0]
  def up
    # Only run if settings table exists (it may not exist during initial migrations)
    return unless ActiveRecord::Base.connection.table_exists?('settings')

    city_value = AppConfig[:city] || ENV['APP_PLACE_CITY'] || 'Ithaca'
    state_value = AppConfig[:state] || ENV['APP_PLACE_STATE'] || 'NY'

    Building.where(city: '').update_all(city: city_value) if Building.table_exists?
    Building.where(state: '').update_all(state: state_value) if Building.table_exists?

    models = [Building].concat CensusYears.map { |year| "Census#{year}Record".safe_constantize }
    models.compact.each do |model|
      next unless model.table_exists?

      model.text_columns.each do |attribute|
        model.where(attribute => '').update_all(attribute => nil)
      end
    end
  end

  def down; end
end
