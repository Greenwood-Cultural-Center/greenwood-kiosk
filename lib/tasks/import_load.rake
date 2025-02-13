# frozen_string_literal: true

# The entire purpose of this is for a developer to import census records into the database.
namespace :import do
  desc 'Import census file into HistoryForge, updating if it exists'
  task :census_load, %i[year file] => [:environment] do |args|
    year = args[year]
    raise ArgumentError('You must pass in a YEAR argument') if year.blank?

    csv_file = args[:file]
    raise ArgumentError('You must pass in a valid file path as the FILE argument') unless File.exist?(csv_file)

    Rake::Task['import:parse_csv'].invoke(year, csv_file)
  end
end

namespace :import do
  task :parse_csv, %i[year file] => [:environment] do |args|
    rows_count = 0
    saved_count = 0

    Setting.load

    require 'csv'

    CSV.foreach(args[:file], headers: true) do |row|
      Rake::Task['import:build_record'].invoke(args[:year], row)
      rows_count += 1
      saved_count += 1
    end

    puts "Managed to load #{saved_count} of #{rows_count} records.\n"
  end
end
namespace :import do
  task :build_record, %i[year row] => [:environment] do |args|
    year = args[:year]
    row = args[:row]

    record = CensusRecord.for_year(year).find_or_initialize_by(
      city: row['City'],
      ward: row['Ward'],
      enum_dist: row['Enum Dist'],
      page_number: row['Sheet'],
      page_side: row['Side'],
      line_number: row['Line']
    )

    row.each do |key, value|
      Rake::Task['import:validate_record'].invoke(record, key, value)
    end
    record
  end
end

namespace :import do
  task :validate_record, %i[record field value] => [:environment] do |args|
    record, *field, value = args

    if field == 'Locality'
      record.locality = Locality.find_or_create_by(name: value, short_name: value)
    elsif !value.nil? && value != ''
      attribute = begin
        DataDictionary.field_from_label(field, year)
      rescue StandardError
        nil
      end
      dc_attribute = attribute&.downcase&.strip
      if dc_attribute && record.has_attribute?(dc_attribute) && dc_attribute != 'person_id'
        if value == 'Yes'
          record[dc_attribute] = true
        elsif DataDictionary.coded_attribute?(dc_attribute)
          code = DataDictionary.code_from_label(value, dc_attribute)
          record[dc_attribute] = code
        else
          record[dc_attribute] = value
        end
      end
    end
    Rake::Task['import:save_record'].invoke(record)
  end
end

namespace :import do
  task :save_record, %i[record] => [:environment] do |args|
    record = args[:record]
    record.created_by = User.first

    address = Address.find_or_initialize_by house_number: record.street_house_number,
                                            prefix: record.street_prefix,
                                            name: record.street_name,
                                            suffix: record.street_suffix,
                                            city: record.city,
                                            is_primary: true

    record.building = address.building || Building.create(
      name: address,
      locality: record.locality,
      building_type_ids: [1],
      lat: row['Latitude'],
      lon: row['Longitude'],
      addresses: [address]
    )
    record.save
  end
end
