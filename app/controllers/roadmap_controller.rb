class RoadmapController < ApplicationController
  before_action :validate_params, only: [:update, :delete]

  def index
    render json: Roadmap.all
  end

  def create
    if params[:step_ids] && params[:step_ids].is_a?(Array)
      roadmap_id, *step_ids = params[:step_ids]
      array_filters, field_path =
        get_mongodb_update_params(step_ids).values_at(:array_filters, :push_or_pull_field_path)

      resp = Roadmap.collection.find_one_and_update(
        { "_id" => BSON::ObjectId(roadmap_id) },
        { "$push" => { field_path => { _id: BSON::ObjectId.new, target: params[:target], steps: [] } } },
        array_filters: array_filters,
        return_document: :after,
      )
      render json: resp.to_json, status: :ok
      return
    end

    target = params[:target]
    resp = Roadmap.create(target: target, steps: [])
    render json: resp.to_json, status: :ok
  end

  def update
    roadmap_id, *step_ids = params[:step_ids]
    array_filters, field_path =
      get_mongodb_update_params(step_ids).values_at(:array_filters, :set_field_path)

    resp = Roadmap.collection.find_one_and_update(
      { "_id" => BSON::ObjectId(roadmap_id) },
      { "$set" => { field_path => params[:target] } },
      array_filters: array_filters,
      return_document: :after,
    )
    render json: resp.to_json, status: :ok
  end

  def delete
    roadmap_id, *remaining_step_ids, pulled_step_id = params[:step_ids]
    roadmap = Roadmap.find(roadmap_id)

    if pulled_step_id.nil?
      resp = roadmap.delete
      render json: resp.to_json, status: :ok
      return
    end

    array_filters, field_path =
      get_mongodb_update_params(remaining_step_ids).values_at(:array_filters, :push_or_pull_field_path)

    parent_step = roadmap
    remaining_step_ids.each do |step_id|
      next_step = parent_step.steps.find { |step| step._id == BSON::ObjectId(step_id) }
      parent_step = next_step
    end

    pulled_step = parent_step.steps.find { |step| step._id == BSON::ObjectId(pulled_step_id) }

    if params[:delete_recursive].nil? || params[:delete_recursive] == false
      Roadmap.collection.find_one_and_update(
        { "_id" => BSON::ObjectId(roadmap_id) },
        { "$push" => { field_path => { "$each" => pulled_step.steps.as_json } } },
        array_filters: array_filters,
        return_document: :after,
      )
    end

    resp = Roadmap.collection.find_one_and_update(
      { "_id" => BSON::ObjectId(roadmap_id) },
      { "$pull" => { field_path => { "_id" => BSON::ObjectId(pulled_step_id) } } },
      array_filters: array_filters,
      return_document: :after,
    )

    render json: resp.to_json, status: :ok
  end

  private

  def validate_params
    validator = RoadmapParamsValidator.new(params)
    render json: validator.errors, status: :unprocessable_entity unless validator.valid?
  end

  def get_mongodb_update_params(step_ids)
    array_filters = []
    set_field_path = ""
    push_or_pull_field_path = "steps"

    step_ids.each_with_index do |step_id, index|
      array_filters << { "level#{index}._id" => BSON::ObjectId(step_id) }
      set_field_path = "#{set_field_path}steps.$[level#{index}]."
      push_or_pull_field_path = "#{push_or_pull_field_path}.$[level#{index}].steps"
    end

    set_field_path = "#{set_field_path}target"

    {
      array_filters: array_filters,
      set_field_path: set_field_path,
      push_or_pull_field_path: push_or_pull_field_path,
    }
  end
end
