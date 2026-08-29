# frozen_string_literal: true

class PrintVatsController < ApplicationController
  include PrintApi

  respond_to :html, :json

  before_action :load_vat, only: [:show, :update, :destroy, :record_maintenance, :swap]

  def index
    authorize PrintVat
    vats = policy_scope(PrintVat).includes(:print_host, :resin_bottle).order(:identity)
    vats = vats.where(print_host_id: params[:print_host_id]) if params[:print_host_id].present?
    respond_to do |format|
      format.json { render json: {print_vats: vats.map { |v| serialize_print_vat(v) }} }
      format.html { redirect_to consumables_path }
    end
  end

  def show
    authorize @vat
    respond_to do |format|
      format.json { render json: {print_vat: serialize_print_vat(@vat)} }
      format.html { redirect_to consumables_path }
    end
  end

  def create
    authorize PrintVat
    @vat = PrintVat.new(vat_params)
    respond_to do |format|
      if @vat.save
        format.json { render json: {print_vat: serialize_print_vat(@vat)}, status: :created }
        format.html { redirect_to consumables_path, notice: t(".success") }
      else
        format.json { render json: {errors: @vat.errors.to_hash}, status: :unprocessable_content }
        format.html { redirect_to consumables_path, alert: @vat.errors.full_messages.to_sentence }
      end
    end
  end

  def update
    authorize @vat
    respond_to do |format|
      if @vat.update(vat_params)
        format.json { render json: {print_vat: serialize_print_vat(@vat)} }
        format.html { redirect_to consumables_path, notice: t(".updated") }
      else
        format.json { render json: {errors: @vat.errors.to_hash}, status: :unprocessable_content }
        format.html { redirect_to consumables_path, alert: @vat.errors.full_messages.to_sentence }
      end
    end
  end

  def destroy
    authorize @vat
    @vat.destroy!
    respond_to do |format|
      format.json { head :no_content }
      format.html { redirect_to consumables_path, notice: t(".destroyed") }
    end
  end

  def record_maintenance
    authorize @vat, :update?
    Print::ConsumableService.new(actor: current_user).record_vat_maintenance!(
      @vat,
      fep_cycles: params[:fep_cycles],
      increment_fep: params.fetch(:increment_fep, 0),
      sync_host: ActiveModel::Type::Boolean.new.cast(params.fetch(:sync_host, true))
    )
    respond_to do |format|
      format.json { render json: {print_vat: serialize_print_vat(@vat.reload)} }
      format.html { redirect_to consumables_path, notice: t(".maintenance_recorded") }
    end
  rescue Print::ConsumableService::Error => e
    respond_to do |format|
      format.json { render_print_error(e) }
      format.html { redirect_to consumables_path, alert: e.message }
    end
  end

  # Swap resin allocation on a vat (REQ-011).
  def swap
    authorize @vat, :update?
    bottle_id = params[:resin_bottle_id].presence
    attrs = {resin_bottle_id: bottle_id}
    attrs[:print_host_id] = params[:print_host_id] if params[:print_host_id].present?
    if @vat.update(attrs)
      respond_to do |format|
        format.json { render json: {print_vat: serialize_print_vat(@vat)} }
        format.html { redirect_to consumables_path, notice: t(".swapped") }
      end
    else
      respond_to do |format|
        format.json { render json: {errors: @vat.errors.to_hash}, status: :unprocessable_content }
        format.html { redirect_to consumables_path, alert: @vat.errors.full_messages.to_sentence }
      end
    end
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
