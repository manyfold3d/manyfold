# syntax = devthefuture/dockerfile-x

INCLUDE docker/base.dockerfile
INCLUDE docker/build.dockerfile
INCLUDE docker/runtime.dockerfile

## STANDARD IMAGE ##########################################

FROM runtime as manyfold
