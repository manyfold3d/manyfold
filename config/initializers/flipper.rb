# This file sets up the various flags that we use to control large-scale features
# using Flipper, a feature flagging gem.
# This isn't strictly necessary to do, but it keeps a list in one place, and removes
# some log warnings when checking features that haven't been enabled yet.

# Note: We're using Flipper for local settings only, no cloud features.

Flipper.add :multiuser # Single or multiuser?
