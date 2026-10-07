#!/usr/bin/env python3
"""Mechanically embed the canonical jq policy in the Harness reference."""
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
policy = (root / 'contracts/terraform-plan-policy.jq').read_text().rstrip()
assert "'" not in policy, 'Inline single-quoted jq must not contain apostrophes'
path = root / 'templates/harness/aws-eks-dev-pipeline-v2.yaml.tftpl'
text = path.read_text()
start = text.index('                          # BEGIN FACTORY PLAN POLICY\n')
end = text.index('                          # END FACTORY PLAN POLICY\n', start)
end += len('                          # END FACTORY PLAN POLICY\n')
body = '\n'.join('                          ' + line for line in policy.splitlines())
generated = ('                          # BEGIN FACTORY PLAN POLICY\n'
             '                          jq -e --arg mode "$DELIVERY_MODE" --arg capability "$CAPABILITY" \'\n'
             + body + '\n                          \' "$plan" >/dev/null\n'
             '                          # END FACTORY PLAN POLICY\n')
updated = text[:start] + generated + text[end:]
if '--check' in sys.argv:
    assert updated == text, 'Harness plan guard differs from canonical policy'
else:
    path.write_text(updated)
