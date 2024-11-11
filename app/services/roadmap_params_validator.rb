class RoadmapParamsValidator
  include ActiveModel::Validations

  attr_reader :step_ids

  validate :verify_array

  def initialize(params)
    @step_ids = params[:step_ids]
  end

  private

  def verify_array
    errors.add(:step_ids, "step_ids must be array") unless step_ids.is_a?(Array)
  end
end
