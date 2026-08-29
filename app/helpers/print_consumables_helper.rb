# frozen_string_literal: true

# Threshold helpers for FEP / LCD visual states (INIT-008/SPEC-007).
module PrintConsumablesHelper
  FEP_LIFE_CYCLES = 500
  LCD_LIFE_HOURS = 2000
  WARNING_RATIO = 0.70
  DANGER_RATIO = 0.90

  module_function

  def fep_level(cycles, max: FEP_LIFE_CYCLES)
    ratio_level(cycles.to_f / max.to_f)
  end

  def lcd_level(hours, max: LCD_LIFE_HOURS)
    ratio_level(hours.to_f / max.to_f)
  end

  def vat_health_level(vat)
    fep_level(vat.fep_cycles)
  end

  def ratio_level(ratio)
    return :danger if ratio >= DANGER_RATIO
    return :warning if ratio >= WARNING_RATIO

    :optimal
  end

  def resin_fill_pct(bottle)
    capacity = bottle.capacity_ml.to_f
    return 0 if capacity <= 0

    ((bottle.remaining_ml.to_f / capacity) * 100).round.clamp(0, 100)
  end

  def resin_low?(bottle)
    resin_fill_pct(bottle) < 40
  end

  def storage_used_pct(used, total)
    return 0 if total.to_i <= 0

    ((used.to_f / total.to_f) * 100).round.clamp(0, 100)
  end
end
