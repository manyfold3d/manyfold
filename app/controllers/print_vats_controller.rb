# frozen_string_literal: true

class PrintVatsController < ApplicationController
  include PrintApi

  respond_to :json

  before_action :load_vat, only: [:show, :update, :destroy, :record_maintenance]

  def index
    authorize PrintVat
    vats = policy_scope(PrintVat).includes(:print_host, :resin_bottle).order(:identity)
    vats = vats.where(print_host_id: params[:print_host_id]) if params[:print_host_id].present?
    render json: {print_vats: vats.map { |v| serialize_print_vat(v) }}
  end

  def show
    authorize @vat
    render json: {print_vat: serialize_print_vat(@vat)}
  end

  def create
    authorize PrintVat
    @vat = PrintVat.new(vat_params)
    if @vat.save
      render json: {print_vat: serialize_print_vat(@vat)}, status: :created
    else
      render json: {errors: @vat.errors.to_hash}, status: :unprocessable_content
    end
  end

  def update
    authorize @vat
    if @vat.update(vat_params)
      render json: {print_vat: serialize_print_vat(@vat)}
    else
      render json: {errors: @vat.errors.to_hash}, status: :unprocessable_content
    end
  end

  def destroy
    authorize @vat
    @vat.destroy!
    head :no_content
  end

  def record_maintenance
    authorize @vat, :update?
    Print::ConsumableService.new(actor: current_user).record_vat_maintenance!(
      @vat,
      fep_cycles: params[:fep_cycles],
      increment_fep: params.fetch(:increment_fep, 0),
      sync_host: ActiveModel::Type::Boolean.new.cast(params.fetch(:sync_host, true))
    )
    render json: {print_vat: serialize_print_vat(@vat.reload)}
  rescue Print::ConsumableService::Error => e
    render_print_error(e)
  end

  private

  def load_vat
    @vat = policy_scope(PrintVat).find(params[:id])
  end

  def vat_params
    params.expect(print_vat: [
      :identity, :fep_cycles, :status, :print_host_id, :resin_bottle_id
    ])
  end
end
