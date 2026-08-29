# frozen_string_literal: true

# Fleet-wide consumables & maintenance UI (INIT-008/SPEC-007 · REQ-011).
class ConsumablesController < ApplicationController
  respond_to :html

  def index
    authorize ResinBottle, :index?
    authorize PrintVat, :index?
    authorize PrintHost, :index?

    @resin_bottles = policy_scope(ResinBottle).includes(:print_host).order(:brand, :color)
    @printers = policy_scope(PrintHost).order(:name)
    @print_vats = policy_scope(PrintVat).includes(:print_host, :resin_bottle).order(:identity)
    @bottles_for_swap = @resin_bottles
  end
end
