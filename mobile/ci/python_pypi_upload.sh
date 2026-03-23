#!/usr/bin/env bash

set -e

if [[ ! -f /.dockerenv ]]; then
    echo "Re-executing python_pypi_upload.sh inside docker..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cd "${SCRIPT_DIR}/../.."
    exec ./ci/run_envoy_docker.sh "bash -c 'cd mobile && ./ci/python_pypi_upload.sh'"
fi

bazel --bazelrc=../user.bazelrc build -c opt --strip=always //library/python:envoy_mobile_wheel --//library/python:python_platform="manylinux2014_x86_64" --@rules_python//python/config_settings:python_version="3.13.1"

python3 -m venv envoy_wheel_test

source envoy_wheel_test/bin/activate
pip install patchelf
pip install auditwheel
auditwheel repair bazel-bin/library/python/envoy_mobile_client-0.5.0-py3-none-manylinux2014_x86_64.whl