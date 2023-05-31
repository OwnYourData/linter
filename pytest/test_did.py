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

def envsubst(text):
    pattern = re.compile(r'\$({}?|[a-zA-Z_]\w*)'.format('|'.join(map(re.escape, os.environ.keys()))))
    return pattern.sub(lambda m: os.getenv(m.group(1)), text)

# admin checks
def test_access():
    response = requests.get(didlint_host)
    assert response.status_code == 200
    response = requests.get(didlint_host + '/version')
    assert response.status_code == 200
    response = requests.get(didlint_host + '/validate?did=did:oyd:zQmZZbVygmbsxWXhP2BH5nW2RMNXSQA3eRqnzfkFXzH3fg1')
    assert response.status_code == 200

# validate DIDs
cwd = os.getcwd()
# doc: https://pypi.org/project/pytest-subprocess/
@pytest.mark.parametrize('input',  glob.glob(cwd+'/03_input/*.doc'))
def test_did(fp, input):
    fp.allow_unregistered(True)
    with open(input) as f:
        did = f.read()
    with open(input.replace("_input/", "_output/")) as f:
        result = f.read()
    command = "curl " + didlint_host + "/api/validate/" + did
    process = subprocess.run(command, shell=True, capture_output=True, text=True)
    assert process.returncode == 0
    if len(result) > 0:
        assert process.stdout.strip() == result.strip()

# validate DID Docs
cwd = os.getcwd()
@pytest.mark.parametrize('input',  glob.glob(cwd+'/03_input/*.json'))
def test_did_doc(fp, input):
    print(input)
    fp.allow_unregistered(True)
    with open(input) as f:
        doc = f.read()
    with open(input.replace("_input/", "_output/")) as f:
        result = f.read()
    command = "echo '"  + doc + "' | curl  -H 'Content-Type: application/json' -d @- -X POST " + didlint_host + "/api/validate"
    process = subprocess.run(command, shell=True, capture_output=True, text=True)
    assert process.returncode == 0
    if len(result) > 0:
        assert process.stdout.strip() == result.strip()
