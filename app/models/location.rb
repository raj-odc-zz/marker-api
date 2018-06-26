class Location < ApplicationRecord
	default_scope { select(:id, :short_name, :long_name, :latitude, :longitude) }
end
