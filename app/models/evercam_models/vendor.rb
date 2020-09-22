class Vendor < Sequel::Model
  REGEX_MAC = /([0-9A-F]{2}[:-]){2,5}([0-9A-F]{2})/i
  one_to_many :vendor_models
  dataset_module do
    def by_exid(val)
      where(exid: val.downcase)
    end

    def by_mac(val)
      where(%("known_macs" @> ARRAY[?]), val.upcase[0, 8])
    end

    def supported
      join(:vendor_models, :vendor_id => :id).distinct(:id).
        select_all(:vendors)
    end
  end

  def known_macs=(val)
    val = Sequel.pg_array(
      val.map(&:upcase).uniq) if val
    values[:known_macs] = val
  end

  def get_model_for(val)
    match_model(val) || default_model
  end

  def default_model
    vendor_models.detect do |f|
      VendorModel::DEFAULT == f.name
    end
  end

  private

  def match_model(val)
    vendor_models.detect do |f|
      VendorModel::DEFAULT != f.name && nil != val.upcase.match(f.name.upcase)
    end
  end
end
