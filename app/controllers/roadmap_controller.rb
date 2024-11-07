class RoadmapController < ApplicationController
  def index
    render json: Roadmap.all
  end

  def create
    if params[:step_ids] # Todo: validate before controller action
      roadmap_id, *step_ids = params[:step_ids]
      array_filters, field_path = get_mongodb_update_params(step_ids).values_at(:array_filters, :push_field_path)

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
    array_filters, field_path = get_mongodb_update_params(step_ids).values_at(:array_filters, :set_field_path)

    resp = Roadmap.collection.find_one_and_update(
      { "_id" => BSON::ObjectId(roadmap_id) },
      { "$set" => { field_path => params[:target] } },
      array_filters: array_filters,
      return_document: :after,
    )
    render json: resp.to_json, status: :ok
  end

  private

  def get_mongodb_update_params(step_ids)
    array_filters = []
    push_field_path = "steps"
    set_field_path = ""

    step_ids.each_with_index do |step_id, index|
      array_filters << { "level#{index}._id" => BSON::ObjectId(step_id) }
      push_field_path = "#{push_field_path}.$[level#{index}].steps"
      set_field_path = "#{set_field_path}steps.$[level#{index}]."
    end

    set_field_path = "#{set_field_path}target"

    {
      array_filters: array_filters,
      push_field_path: push_field_path,
      set_field_path: set_field_path,
    }
  end
end
