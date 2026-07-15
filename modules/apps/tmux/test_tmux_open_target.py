import importlib.util
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

MODULE_PATH = Path(__file__).with_name("tmux-open-target.py")
SPEC = importlib.util.spec_from_file_location("tmux_open_target", MODULE_PATH)
opener = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(opener)


class FileParsingTests(unittest.TestCase):
    def test_split_file_location_with_line_and_column(self):
        self.assertEqual(opener.split_file_location("src/app.py:12:3"), ("src/app.py", 12, 3))

    def test_split_file_location_with_line_only(self):
        self.assertEqual(opener.split_file_location("src/app.py:12"), ("src/app.py", 12, None))

    def test_token_at_extracts_file_and_trims_trailing_punctuation(self):
        line = "error at modules/apps/tmux/base.conf:55:3,"

        self.assertEqual(
            opener.token_at(line, line.index("base.conf")), "modules/apps/tmux/base.conf:55:3"
        )

    def test_target_from_text_prefers_existing_file_inside_selected_range(self):
        with tempfile.TemporaryDirectory() as tmp:
            cwd = Path(tmp)
            path = cwd / "src" / "app.py"
            path.parent.mkdir()
            path.touch()

            self.assertEqual(
                opener.target_from_text("failed at src/app.py:12:3", cwd), "src/app.py:12:3"
            )

    def test_open_target_runs_nvr_for_existing_file_with_position(self):
        with tempfile.TemporaryDirectory() as tmp:
            cwd = Path(tmp)
            path = cwd / "src" / "app.py"
            path.parent.mkdir()
            path.touch()

            with (
                patch.object(opener, "select_nvr_server", return_value="/run/user/1000/nvim.1"),
                patch.object(
                    opener.subprocess,
                    "Popen",
                ) as popen,
            ):
                opener.open_target("src/app.py:12:3", cwd, pane=None)

            popen.assert_called_once_with(
                [
                    "nvr",
                    "--servername",
                    "/run/user/1000/nvim.1",
                    "--remote",
                    "+call cursor(12,3)",
                    str(path),
                ],
                stdout=opener.subprocess.DEVNULL,
                stderr=opener.subprocess.DEVNULL,
            )

    def test_select_nvr_server_prefers_server_with_attached_ui(self):
        with (
            patch.object(
                opener, "nvr_serverlist", return_value=["/tmp/nvimsocket", "/run/user/1000/nvim.1"]
            ),
            patch.object(
                opener,
                "nvr_ui_count",
                side_effect=lambda server: 1 if server == "/run/user/1000/nvim.1" else 0,
            ),
        ):
            self.assertEqual(opener.select_nvr_server(), "/run/user/1000/nvim.1")


class UrlParsingTests(unittest.TestCase):
    def test_clean_url_trims_wrapping_punctuation(self):
        self.assertEqual(
            opener.clean_token("(https://example.com/path?q=1)."), "https://example.com/path?q=1"
        )

    def test_target_from_text_prefers_url_inside_selected_range(self):
        self.assertEqual(
            opener.target_from_text("see https://example.com/path?q=1 for details", Path("/tmp")),
            "https://example.com/path?q=1",
        )

    def test_file_url_is_url_target(self):
        self.assertTrue(opener.is_url_target("file:///tmp/example.txt"))

    def test_mailto_is_url_target(self):
        self.assertTrue(opener.is_url_target("mailto:user@example.com"))

    def test_open_target_runs_xdg_open_for_url(self):
        with patch.object(opener.subprocess, "Popen") as popen:
            opener.open_target("(https://example.com/path?q=1).", Path("/tmp"), pane=None)

        popen.assert_called_once_with(
            ["xdg-open", "https://example.com/path?q=1"],
            stdout=opener.subprocess.DEVNULL,
            stderr=opener.subprocess.DEVNULL,
        )


if __name__ == "__main__":
    unittest.main()
