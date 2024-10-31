class RoadmapController < ApplicationController
  def index
    render json: Roadmap.all
  end

  def create
    target = params[:target]
    resp = Roadmap.create(target: target, steps: [])
    render json: resp, status: :ok
  end
end
