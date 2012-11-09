class User < ActiveRecord::Base
  #set_primary_key :api_key
  self.primary_key = 'api_key'
  attr_accessible :api_key,:sn,:ln
end
