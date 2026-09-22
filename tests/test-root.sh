#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
scratch=$(mktemp -d "${TMPDIR:-/tmp}/factory-boundary-test.XXXXXXXX")
# This fixture has no remote backend. It never applies or uses credentials.
trap 'find "$scratch" -depth -delete' EXIT
for template in "$root"/templates/terraform-root/aws-eks-dev-v2/*.tf.tftpl; do
  filename=${template##*/}
  test "$filename" = backend.tf.tftpl && continue
  cp "$template" "$scratch/${filename%.tftpl}"
done
mkdir "$scratch/tests"
cp "$root/tests/root-permissions-boundary.tftest.hcl" "$scratch/tests/"
tofu -chdir="$scratch" fmt
tofu -chdir="$scratch" init -backend=false -input=false
tofu -chdir="$scratch" validate
tofu -chdir="$scratch" test
