# frozen_string_literal: true

class ResinBottlesController < ApplicationController
  include PrintApi

  respond_to :html, :json

  before_action :load_bottle, only: [:show, :update, :destroy]

  def index
    authorize ResinBottle
    bottles = policy_scope(ResinBottle).includes(:print_host).order(:brand)
    bottles = bottles.where(print_host_id: params[:print_host_id]) if params[:print_host_id].present?
    respond_to do |format|
      format.json { render json: {resin_bottles: bottles.map { |b| serialize_resin_bottle(b) }} }
      format.html { redirect_to consumables_path }
    end
  end

  def show
    authorize @bottle
    respond_to do |format|
      format.json { render json: {resin_bottle: serialize_resin_bottle(@bottle)} }
      format.html { redirect_to consumables_path }
    end
  end

  def create
    authorize ResinBottle
    @bottle = ResinBottle.new(bottle_params)
    respond_to do |format|
      if @bottle.save
        format.json { render json: {resin_bottle: serialize_resin_bottle(@bottle)}, status: :created }
        format.html { redirect_to consumables_path, notice: t(".success") }
      else
        format.json { render json: {errors: @bottle.errors.to_hash}, status: :unprocessable_content }
        format.html { redirect_to consumables_path, alert: @bottle.errors.full_messages.to_sentence }
      end
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
      respond_to do |format|
        format.json { render json: {errors: @bottle.errors.to_hash}, status: :unprocessable_content }
        format.html { redirect_to consumables_path, alert: @bottle.errors.full_messages.to_sentence }
      end
      return
    end
    respond_to do |format|
      format.json { render json: {resin_bottle: serialize_resin_bottle(@bottle.reload)} }
      format.html { redirect_to consumables_path, notice: t(".adjusted") }
    end
  rescue Print::ConsumableService::Error => e
    respond_to do |format|
      format.json { render_print_error(e) }
      format.html { redirect_to consumables_path, alert: e.message }
    end
  end

  def destroy
    authorize @bottle
    @bottle.destroy!
    respond_to do |format|
      format.json { head :no_content }
      format.html { redirect_to consumables_path, notice: t(".destroyed") }
    end
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
