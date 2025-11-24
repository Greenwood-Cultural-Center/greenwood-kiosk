# frozen_string_literal: true

# Provides application configuration values. Mostly a facade for Setting.
class AppConfig
  def self.[](key)
    # Only try to load settings if the table exists (e.g., during migrations)
    if Setting.table_exists?
      Setting.load unless Setting.loaded?
      Setting.value_of(key) || ENV.fetch(key.to_s.upcase, nil)
    else
      ENV.fetch(key.to_s.upcase, nil)
    end
  end
end
