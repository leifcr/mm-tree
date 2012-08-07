class TreeInfo
  include MongoMapper::EmbeddedDocument
  attr_accessible :nv, :dv, :snv, :sdv, :path, :depth, :position #, :parent_id

  key :nv, Integer
  key :dv, Integer
  key :snv, Integer
  key :sdv, Integer
  key :path, Array, :typecast => 'ObjectId' # might need to be string instead?
  key :depth, Integer
  key :position, Integer
  # key :parent_id, ObjectId

  timestamps!

end
