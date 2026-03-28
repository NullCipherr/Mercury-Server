#!/usr/bin/env bash
set -euo pipefail

curl -i http://127.0.0.1:8080/health
curl -i http://127.0.0.1:8080/api/hello
curl -i http://127.0.0.1:8080/metrics
curl -i http://127.0.0.1:8080/
curl -i http://127.0.0.1:8080/static/index.html
