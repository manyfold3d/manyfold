# Monkeypatch Zaru to tweak sanitization rules
class Zaru
  # Allow multiple spaces in filenames
  UNICODE_WHITESPACE = /[[:space:]]/u
end
