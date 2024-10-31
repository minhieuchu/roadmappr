class Roadmap
  include Mongoid::Document
  include Mongoid::Timestamps
  field :target, type: String

  embeds_many :steps, class_name: "Roadmap"
end
