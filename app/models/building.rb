# == Schema Information
#
# Table name: buildings
#
#  id                    :integer          not null, primary key
#  name                  :string           not null
#  city                  :string
#  state                 :string
#  postal_code           :string
#  year_earliest         :integer
#  year_latest           :integer
#  building_type_id      :integer
#  description           :text
#  lat                   :decimal(15, 10)
#  lon                   :decimal(15, 10)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  year_earliest_circa   :boolean          default(FALSE)
#  year_latest_circa     :boolean          default(FALSE)
#  address_house_number  :string
#  address_street_prefix :string
#  address_street_name   :string
#  address_street_suffix :string
#  stories               :float
#  annotations_legacy    :text
#  lining_type_id        :integer
#  frame_type_id         :integer
#  block_number          :string
#  created_by_id         :integer
#  reviewed_by_id        :integer
#  reviewed_at           :datetime
#  investigate           :boolean          default(FALSE)
#  investigate_reason    :string
#  notes                 :text
#  locality_id           :bigint
#  building_types_mask   :integer
#  parent_id             :bigint
#  hive_year             :integer
#
# Indexes
#
#  index_buildings_on_building_type_id  (building_type_id)
#  index_buildings_on_created_by_id     (created_by_id)
#  index_buildings_on_frame_type_id     (frame_type_id)
#  index_buildings_on_lining_type_id    (lining_type_id)
#  index_buildings_on_locality_id       (locality_id)
#  index_buildings_on_parent_id         (parent_id)
#  index_buildings_on_reviewed_by_id    (reviewed_by_id)
#

# frozen_string_literal: true

# Rails model for buildings. Census records are attached to buildings. They also have photos and some
# metadata originally designed and provided by Historic Ithaca.
class Building < ApplicationRecord
  include Moderation
  include Flaggable
  include Versioning

  self.ignored_columns = %i[city state postal_code]

  has_rich_text :description

  define_enumeration :address_street_prefix, STREET_PREFIXES
  define_enumeration :address_street_suffix, STREET_SUFFIXES

  belongs_to :locality

  belongs_to :parent, class_name: 'Building', optional: true
  has_many :children, class_name: 'Building', foreign_key: :parent_id

  has_many :addresses, dependent: :destroy, autosave: true
  accepts_nested_attributes_for :addresses, allow_destroy: true, reject_if: proc { |p| p['name'].blank? }

  has_and_belongs_to_many :architects

  has_many :annotations, dependent: :destroy
  accepts_nested_attributes_for :annotations, allow_destroy: true, reject_if: proc { |p| p['annotation_text'].blank? }

  CensusYears.each do |year|
    has_many :"census_#{year}_records", dependent: :nullify, class_name: "Census#{year}Record"
  end
  has_and_belongs_to_many :photos, class_name: 'Photograph', dependent: :nullify

  before_validation :check_locality
  validates :name, presence: true, length: { maximum: 255 }
  validates :year_earliest, :year_latest, numericality: { minimum: 1500, maximum: 2100, allow_nil: true }
  validate :validate_primary_address
  validates :addresses, length: { minimum: 1, too_short: ' - a building must have at least one.' }

  delegate :name, to: :frame_type, prefix: true, allow_nil: true
  delegate :name, to: :lining_type, prefix: true, allow_nil: true

  scope :as_of_year, lambda { |year|
    where('(year_earliest is null and year_latest is null) or (year_earliest<=:year and (year_latest is null or year_latest>=:year)) or (year_earliest is null and year_latest>=:year)', year:)
  }

  scope :as_of_year_eq, lambda { |year|
    where('(year_earliest<=:year and (year_latest is null or year_latest>=:year)) or (year_earliest is null and year_latest>=:year)', year:)
  }

  scope :without_residents, lambda {
    join_clause = []
    where_clause = []
    CensusYears.each do |year|
      join_clause << "LEFT OUTER JOIN census_#{year}_records ON census_#{year}_records.building_id=buildings.id"
      where_clause << "census_#{year}_records IS NULL"
    end
    joins(join_clause.join(' '))
      .where(where_clause.join(' AND '))
      .building_types_id_in(3)
  }

  scope :order_by, lambda { |col, dir|
    order(Arel.sql(sanitize_sql_for_order("#{col} #{dir}")))
  }

  scope :order_by_street_address, lambda { |dir|
    all
      .joins('LEFT OUTER JOIN addresses ON addresses.building_id=buildings.id AND addresses.is_primary=TRUE')
      .group('buildings.id, addresses.id')
      .order('addresses.name' => dir)
      .order('addresses.prefix' => dir)
      .order('addresses.suffix' => dir)
      .order(Arel.sql("substring(addresses.house_number, '^[0-9]+')::int") => dir)
  }

  scope :by_street_address, -> { order_by_street_address('asc') }

  scope :with_multiple_addresses, lambda {
    all
      .joins(:addresses)
      .group('buildings.id, addresses.name')
      .having('COUNT(addresses.name) > 1')
  }

  scope :building_types_id_in, lambda { |*ids|
    if ids.empty?
      where('building_types_mask > 0')
    else
      where 'building_types_mask & ? > 0', BuildingType.mask_for(ids)
    end
  }

  scope :building_types_id_not_in, lambda { |*ids|
    if ids.empty?
      where('building_types_mask = 0')
    else
      where.not 'building_types_mask & ? > 0', BuildingType.mask_for(ids)
    end
  }

  scope :building_types_id_null, -> { where(building_types_mask: nil) }
  scope :building_types_id_not_null, -> { where.not(building_types_mask: nil) }

  def self.ransackable_scopes(_auth_object = nil)
    %i[as_of_year without_residents as_of_year_eq
       building_types_id_in building_types_id_not_in building_types_id_null building_types_id_not_null]
  end

  Geocoder.configure(
    timeout: 2,
    use_https: true,
    lookup: :google,
    api_key: AppConfig[:geocoding_key]
  )

  geocoded_by :full_street_address, latitude: :lat, longitude: :lon
  after_validation :do_the_geocode, if: :new_record?

  ransacker :street_address, formatter: proc { |v| v.mb_chars.downcase.to_s } do
    addresses = Address.arel_table
    Arel::Nodes::NamedFunction.new('LOWER',
                                   [Arel::Nodes::NamedFunction.new('concat_ws',
                                                                   [Arel::Nodes::Quoted.new(' '),
                                                                    addresses[:house_number],
                                                                    addresses[:prefix],
                                                                    addresses[:name],
                                                                    addresses[:suffix]])])
  end

  alias_attribute :latitude, :lat
  alias_attribute :longitude, :lon
  alias_attribute :longitude, :lon

  def proper_name?
    name && (address_house_number.blank? || !name.include?(address_house_number))
  end

  def do_the_geocode
    return if Rails.env.test?

    geocode
  rescue Errno::ENETUNREACH
    nil
  end

  # TODO: this presentation stuff overlaps with the BuildingPresenter. Make the Buildings::MainController use the presenter.
  def full_street_address
    [street_address, city].join(' ')
  end

  def architects_list
    architects.map(&:name).join(', ')
  end

  def architects_list=(value)
    self.architects = value.split(',').map(&:strip).map { |item| Architect.find_or_create_by(name: item) }
  end

  def address
    return @address if defined?(@address)

    @address = addresses&.detect(&:is_primary)
  end

  def address_house_number
    address&.house_number
  end

  def address_street_prefix
    address&.prefix
  end

  def address_street_name
    address&.name
  end

  def address_street_suffix
    address&.suffix
  end

  def city
    address&.city
  end

  def address_year_earliest
    address&.year_earliest
  end

  def address_year_latest
    address&.year_latest
  end

  def street_address_for_building_id(year)
    addresses
      .to_a.select { |a| a.year.blank? || a.year <= year }.min&.address
  end

  def street_address
    addresses.sort { |a,b| b.year <=> a.year }.map(&:address_with_year).join("\n")
  end

  def primary_street_address
    (addresses.detect(&:is_primary) || addresses.first || OpenStruct.new(address: 'No address')).address
  end

  def ensure_primary_address
    addresses.build(is_primary: true) if new_record? && addresses.blank?
  end

  def name_the_house
    return if name.present?

    self.name = primary_street_address
  end
  before_validation :name_the_house

  def neighbors
    lat? ? nearbys(0.1).limit(8).includes(:addresses) : []
  end

  attr_writer :residents

  def residents
    Buildings::FindResidents.run!(building: self, reviewed_only: true)
  end
  memoize :residents

  def residents_by_year
    residents&.group_by(&:year)
  end
  memoize :residents_by_year

  CensusYears.each do |year|
    define_method("families_in_#{year}") do
      residents_by_year[year]&.group_by(&:family_id)
    end
  end

  def next_address
    Address.new.tap do |address|
      next if new_record? || addresses.blank?

      last_address = addresses.last
      address.name = last_address.name
      address.prefix = last_address.prefix
      address.suffix = last_address.suffix
      address.city = last_address.city
    end
  end

  def frame_type
    ConstructionMaterial.find frame_type_id
  end
  memoize :frame_type

  def lining_type
    ConstructionMaterial.find lining_type_id
  end
  memoize :lining_type

  def building_types
    BuildingType.from_mask(building_types_mask)
  end

  def building_type_ids
    BuildingType.ids_from_mask(building_types_mask)
  end

  def building_type_ids=(ids)
    self.building_types_mask = BuildingType.mask_from_ids(ids)
  end

  private

  def validate_primary_address
    primary_addresses = addresses.to_a.select(&:is_primary)
    if primary_addresses.blank?
      errors.add(:base, 'Primary address missing.')
    elsif primary_addresses.size > 1
      errors.add(:base, 'Multiple primary addresses not allowed.')
    end
  end

  def check_locality
    return if locality_id.present?

    self.locality = Locality.first if Locality.count == 1
  end
end
