#!/bin/bash

gcloud compute instances create reddit-app-full\
      --image-family reddit-full \
      --machine-type=g1-small \
      --tags puma-server \
      --restart-on-failure
