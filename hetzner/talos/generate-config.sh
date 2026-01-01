#!/bin/bash

talosctl gen config talos-k8s-hcloud-tutorial https://${CONTROLPLANE_IP}:6443
talosctl validate --config controlplane.yaml --mode cloud
talosctl validate --config worker.yaml --mode cloud
