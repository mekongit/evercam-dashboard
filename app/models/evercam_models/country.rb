class Country < Sequel::Model
  one_to_many :users
  def self.by_iso3166(val)
    first(iso3166_a2: val)
  end
end
