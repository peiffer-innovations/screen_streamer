#!/bin/sh

flutter packages upgrade

pushd examples/receiver
flutter packages upgrade
popd

pushd examples/sender
flutter packages upgrade
popd