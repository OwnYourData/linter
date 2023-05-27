import pytest
import os
import re
import sys
import glob
import requests
import subprocess
from pathlib import Path

# test groups
# 01 - SOyA <- current
# 02 - linter
# 03 - DID

didlint_host = os.getenv('DIDLINT_HOST') or "https://didlint.ownyourdata.eu"
os.environ["DIDLINT_HOST"] = didlint_host

# configuration specific to tests
# if lint_host == "http://localhost:3050":

# else:

def envsubst(text):
    pattern = re.compile(r'\$({}?|[a-zA-Z_]\w*)'.format('|'.join(map(re.escape, os.environ.keys()))))
    return pattern.sub(lambda m: os.getenv(m.group(1)), text)

# 00 - Admin
def test_access():
    response = requests.get(didlint_host)
    assert response.status_code == 200
    response = requests.get(didlint_host + '/version')
    assert response.status_code == 200
    response = requests.get(didlint_host + '/validate?did=did:oyd:zQmZZbVygmbsxWXhP2BH5nW2RMNXSQA3eRqnzfkFXzH3fg1')
    assert response.status_code == 200

cwd = os.getcwd()
@pytest.mark.parametrize('input',  sorted(glob.glob(cwd+'/03_input/*.doc')))
def test_01_organisations(fp, input):
    fp.allow_unregistered(True)
    with open(input) as f:
        content = f.read()
    with open(input.replace(".doc", ".cmd")) as f:
        command = f.read()
    with open(input.replace("_input/", "_output/")) as f:
        result = envsubst(f.read())
    if len(content) > 0:
        command = "cat " + input + " | envsubst | " + command
    process = subprocess.run(command, shell=True, capture_output=True, text=True)
    assert process.returncode == 0
    if len(result) > 0:
        assert process.stdout.strip() == result.strip()
