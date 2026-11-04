"""Fast, dependency-free checks for the repository's build contract."""

from __future__ import annotations

import re
import shlex
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class RepositoryIntegrityTests(unittest.TestCase):
    def setUp(self) -> None:
        self.cmake = (ROOT / "CMakeLists.txt").read_text(encoding="utf-8")

    def test_cmake_project_sources_exist(self) -> None:
        match = re.search(
            r"(?ms)^set\(\s*PROJECT_SOURCES\b(.*?)^\)",
            self.cmake,
        )
        self.assertIsNotNone(match, "CMakeLists.txt must define PROJECT_SOURCES")

        missing: list[str] = []
        for raw_line in match.group(1).splitlines():
            source_line = raw_line.split("#", 1)[0].strip()
            for source in shlex.split(source_line):
                if "$" in source:
                    # Platform-dependent CMake lists are validated by the real build.
                    continue
                if not (ROOT / source).is_file():
                    missing.append(source)

        self.assertEqual(
            missing,
            [],
            "CMakeLists.txt references source files that are missing",
        )

    def test_cmake_includes_exist(self) -> None:
        includes = re.findall(
            r"(?m)^\s*include\(\s*[\"']?([^)'\"\s]+)",
            self.cmake,
        )
        missing = [path for path in includes if not (ROOT / path).is_file()]
        self.assertEqual(missing, [], "CMake include files must exist")

    def test_qhotkey_submodule_is_declared(self) -> None:
        gitmodules = (ROOT / ".gitmodules").read_text(encoding="utf-8")
        self.assertIn("path = 3rdparty/QHotkey", gitmodules)
        self.assertRegex(
            self.cmake,
            r"add_subdirectory\(\s*3rdparty/QHotkey\s*\)",
        )

    def test_core_dependency_revisions_are_full_commit_ids(self) -> None:
        pin_file = ROOT / "libs" / "get_source_env.sh"
        content = pin_file.read_text(encoding="utf-8")
        pins = dict(
            re.findall(
                r'(?m)^export\s+(COMMIT_[A-Z0-9_]+)="([0-9a-fA-F]+)"\s*$',
                content,
            )
        )

        required = {"COMMIT_SING_BOX", "COMMIT_SING_QUIC", "COMMIT_LIBNEKO"}
        self.assertTrue(required.issubset(pins), "All core source revisions must be pinned")
        for name in sorted(required):
            self.assertRegex(
                pins[name],
                r"^[0-9a-fA-F]{40}$",
                f"{name} must be a full 40-character Git commit ID",
            )

        source_script = (ROOT / "libs" / "get_source.sh").read_text(encoding="utf-8")
        for name in required:
            self.assertIn(name, source_script)

    def test_release_version_is_not_empty(self) -> None:
        version = (ROOT / "nekoray_version.txt").read_text(encoding="utf-8").strip()
        self.assertTrue(version, "nekoray_version.txt must contain a version")

    def test_ci_covers_linux_and_windows(self) -> None:
        workflow = (ROOT / ".github" / "workflows" / "ci.yml").read_text(
            encoding="utf-8"
        )
        self.assertIn("ubuntu-24.04", workflow)
        self.assertIn("windows-2025", workflow)
        self.assertIn("cmake --build build", workflow)


if __name__ == "__main__":
    unittest.main()
