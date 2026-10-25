"""Exercise the actual compiled reader with a fake, credential-free JSON-RPC server."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

READER = Path(__file__).resolve().parents[1] / 'dist/CodexBar.app/Contents/MacOS/UsageReader'
SERVER = '''#!/usr/bin/env python3
import json, os, sys
for line in sys.stdin:
    request = json.loads(line)
    method = request['method']
    if method == 'initialize':
        assert request['params']['clientInfo']['name'] == 'codexbar'
        print(json.dumps({'id':request['id'],'result':{}}), flush=True)
    elif method == 'initialized':
        initialized = True
    elif method == 'account/rateLimits/read':
        assert initialized
        mode = os.environ['TEST_MODE']
        window = {'usedPercent':18,'windowDurationMins':300,'resetsAt':2000000000}
        quota = {'primary':window,'secondary':None}
        if mode == 'error':
            result = {'error':{'message':'DO_NOT_EXPOSE_BACKEND_DETAILS'}}
        elif mode == 'legacy':
            result = {'result':{'rateLimits':quota}}
        elif mode == 'empty':
            result = {'result':{}}
        else:
            result = {'result':{'rateLimitsByLimitId':{'codex':quota},'rateLimits':{'primary':{'usedPercent':99}}}}
        print(json.dumps({'method':'unrelated/notification'}), flush=True)
        print(json.dumps(dict(id=request['id'], **result)), flush=True)
'''

class ReaderTests(unittest.TestCase):
    def run_reader(self, mode, language="zh-Hans"):
        with tempfile.TemporaryDirectory() as directory:
            server = Path(directory) / 'codex'
            server.write_text(SERVER)
            server.chmod(0o755)
            result = subprocess.run([str(READER)], env=dict(os.environ, CODEX_BINARY=str(server), TEST_MODE=mode, CODEXBAR_LANGUAGE=language), capture_output=True, text=True, timeout=10)
            return result.returncode, json.loads(result.stdout)

    def test_current_bucket_preferred_and_notifications_ignored(self):
        code, result = self.run_reader('current')
        self.assertEqual(code, 0)
        self.assertEqual(result['windows'][0]['usedPercent'], 18)
        self.assertEqual(len(result['windows']), 1)

    def test_legacy_response(self):
        code, result = self.run_reader('legacy')
        self.assertEqual(code, 0)
        self.assertEqual(result['windows'][0]['windowDurationMins'], 300)

    def test_error_is_sanitized(self):
        code, result = self.run_reader('error')
        self.assertEqual(code, 1)
        self.assertIn('登录', result['error'])
        self.assertNotIn('DO_NOT_EXPOSE', result['error'])

    def test_missing_quota_is_not_fabricated(self):
        code, result = self.run_reader('empty')
        self.assertEqual(code, 0)
        self.assertEqual(result['windows'], [])

    def test_english_error(self):
        code, result = self.run_reader('error', 'en')
        self.assertEqual(code, 1)
        self.assertIn('signed in with ChatGPT', result['error'])
        self.assertNotIn('登录', result['error'])
