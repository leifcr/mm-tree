class TreeInfo
  include MongoMapper::EmbeddedDocument
  plugin MongoMapper::Plugins::Dirty
  attr_accessible :nv, :dv, :snv, :sdv, :path, :depth, :position #, :parent_id

  key :nv, Integer, :default => 0
  key :dv, Integer, :default => 0
  key :snv, Integer, :default => 0
  key :sdv, Integer, :default => 0
  key :path, Array, :typecast => 'ObjectId' # might need to be string instead?
#  key :depth, Integer

  timestamps!

end
