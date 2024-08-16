#!/usr/bin/env bash
set -Eeuo pipefail

curl \
  -o data/gold_standard_dataset.jsonl \
  https://raw.githubusercontent.com/ChadiHelwe/MAFALDA/0df434477b914a20f55c0592ba05a53fe924c65b/datasets/gold_standard_dataset.jsonl
