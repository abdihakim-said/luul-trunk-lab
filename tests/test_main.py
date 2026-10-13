import os
import unittest
from unittest import mock

from app import main


class RouteTests(unittest.TestCase):
    def test_health(self):
        self.assertEqual(main.route("/health"), (200, {"status": "ok"}))

    def test_unknown_path_is_404(self):
        status, _ = main.route("/nope")
        self.assertEqual(status, 404)

    def test_version_uses_git_sha(self):
        with mock.patch.dict(os.environ, {"GIT_SHA": "abc123"}):
            _, body = main.route("/version")
        self.assertEqual(body["commit"], "abc123")


class FeatureFlagTests(unittest.TestCase):
    def test_old_greeting_when_flag_off(self):
        self.assertEqual(main.greeting({"new_greeting": False}), "Hello from Luul Solutions")

    def test_new_greeting_when_flag_on(self):
        self.assertEqual(main.greeting({"new_greeting": True}), "Welcome to Luul Solutions platform!")

    def test_env_var_overrides_flag_file(self):
        with mock.patch.dict(os.environ, {"FLAG_NEW_GREETING": "true"}):
            self.assertTrue(main.load_flags()["new_greeting"])


if __name__ == "__main__":
    unittest.main()
