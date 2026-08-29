# frozen_string_literal: true

class ResinBottlesController < ApplicationController
  include PrintApi

  respond_to :json

  before_action :load_bottle, only: [:show, :update, :destroy]

  def index
    authorize ResinBottle
    bottles = policy_scope(ResinBottle).includes(:print_host).order(:brand)
    bottles = bottles.where(print_host_id: params[:print_host_id]) if params[:print_host_id].present?
    render json: {resin_bottles: bottles.map { |b| serialize_resin_bottle(b) }}
  end

  def show
    authorize @bottle
    render json: {resin_bottle: serialize_resin_bottle(@bottle)}
  end

  def create
    authorize ResinBottle
    @bottle = ResinBottle.new(bottle_params)
    if @bottle.save
      render json: {resin_bottle: serialize_resin_bottle(@bottle)}, status: :created
    else
      render json: {errors: @bottle.errors.to_hash}, status: :unprocessable_content
    end
  end

  def update
    authorize @bottle
    remaining = bottle_params[:remaining_ml]
    other = bottle_params.except(:remaining_ml)

    if remaining.present?
      Print::ConsumableService.new(actor: current_user).adjust_bottle!(@bottle, remaining_ml: remaining)
    end
    if other.present? && !@bottle.update(other)
      render json: {errors: @bottle.errors.to_hash}, status: :unprocessable_content
      return
    end
    render json: {resin_bottle: serialize_resin_bottle(@bottle.reload)}
  rescue Print::ConsumableService::Error => e
    render_print_error(e)
  end

  def destroy
    authorize @bottle
    @bottle.destroy!
    head :no_content
  end

  private

  def load_bottle
    @bottle = policy_scope(ResinBottle).find(params[:id])
  end

  def bottle_params
    params.expect(resin_bottle: [
      :brand, :color, :remaining_ml, :capacity_ml, :opened_on, :print_host_id
    ])
  end
end
