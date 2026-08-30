# frozen_string_literal: true

# INIT-013/SPEC-002 — in-memory Redis stand-in for Performance::Telemetry / Prune specs.
# Asserts KEYS is never used; implements SCAN / MGET / TTL / DEL only.
class PerformanceRedisFake
  KeysForbidden = Class.new(StandardError)

  def initialize
    @store = {} # key => {value:, expire_at:}
    @scan_calls = 0
  end

  attr_reader :scan_calls

  def set(key, value, ex: nil)
    expire_at = ex ? Process.clock_gettime(Process::CLOCK_MONOTONIC) + ex.to_i : nil
    @store[key.to_s] = {value: value.to_s, expire_at: expire_at}
    "OK"
  end

  def get(key)
    entry = entry_for(key)
    entry && entry[:value]
  end

  def mget(*keys)
    keys.flatten.map { |k| get(k) }
  end

  def ttl(key)
    entry = @store[key.to_s]
    return -2 unless entry
    return -1 if entry[:expire_at].nil?

    remaining = (entry[:expire_at] - Process.clock_gettime(Process::CLOCK_MONOTONIC)).ceil
    if remaining <= 0
      @store.delete(key.to_s)
      -2
    else
      remaining
    end
  end

  def del(*keys)
    keys.flatten.count { |k| @store.delete(k.to_s) }
  end

  def scan(cursor, match: "*", count: 10)
    @scan_calls += 1
    all = matching_keys(match)
    cursor_i = cursor.to_i
    batch = all.slice(cursor_i, count) || []
    next_cursor = cursor_i + count
    next_cursor = 0 if next_cursor >= all.size
    [next_cursor.to_s, batch]
  end

  def scan_each(match: "*", count: 10, &block)
    return enum_for(:scan_each, match: match, count: count) unless block

    cursor = "0"
    loop do
      cursor, batch = scan(cursor, match: match, count: count)
      batch.each(&block)
      break if cursor.to_s == "0"
    end
  end

  def keys(_pattern = "*")
    raise KeysForbidden, "KEYS is forbidden on Performance telemetry/prune paths (INIT-013/SPEC-002)"
  end

  # rubocop:disable Rails/Delegate -- store is a Hash, not a collaborator object
  def size
    @store.size
  end
  # rubocop:enable Rails/Delegate

  def key_list
    @store.keys
  end

  private

  def entry_for(key)
    entry = @store[key.to_s]
    return nil unless entry
    if entry[:expire_at] && entry[:expire_at] <= Process.clock_gettime(Process::CLOCK_MONOTONIC)
      @store.delete(key.to_s)
      return nil
    end
    entry
  end

  def matching_keys(match)
    pattern = Regexp.new("\\A#{Regexp.escape(match).gsub("\\*", ".*")}\\z")
    @store.keys.select { |k| k.match?(pattern) }.sort
  end
end
