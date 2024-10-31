class RoadmapController < ApplicationController
  def index
    render json: Roadmap.all
  end

  def create
    if params[:step_ids] # Todo: validate array type before controller action
      roadmap_id, *step_ids = params[:step_ids]
      mongodb_update_array_filters = []
      mongodb_update_field_path = "steps"

      step_ids.each_with_index do |step_id, index|
        mongodb_update_array_filters << { "level#{index}._id" => BSON::ObjectId(step_id) }
        mongodb_update_field_path = "#{mongodb_update_field_path}.$[level#{index}].steps"
      end

      resp = Roadmap.collection.find_one_and_update(
        { "_id" => BSON::ObjectId(roadmap_id) },
        { "$push" => { mongodb_update_field_path => { _id: BSON::ObjectId.new, target: params[:target], steps: [] } } },
        array_filters: mongodb_update_array_filters,
        return_document: :after,
      )
      render json: resp.to_json, status: :ok
      return
    end

    target = params[:target]
    resp = Roadmap.create(target: target, steps: [])
    render json: resp.to_json, status: :ok
  end
end
