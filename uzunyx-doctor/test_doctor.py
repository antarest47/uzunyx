"""Tests of the decisions of uzunyx-doctor, with made-up apt outputs."""
import importlib.machinery
import importlib.util
import os
import tempfile
import unittest

here = os.path.dirname(os.path.abspath(__file__))
loader = importlib.machinery.SourceFileLoader("doctor", os.path.join(here, "uzunyx-doctor"))
spec = importlib.util.spec_from_loader("doctor", loader)
doctor = importlib.util.module_from_spec(spec)
loader.exec_module(doctor)


class Plans(unittest.TestCase):
    def test_nothing(self):
        plan = doctor.make_plan("0 upgraded, 0 newly installed\n")
        self.assertEqual(plan.upgrades, [])
        self.assertFalse(plan.desktop or plan.blocked or plan.needs_question)

    def test_ordinary_packages_dont_touch_the_desktop(self):
        plan = doctor.make_plan("Inst curl [8] (9 Debian:testing [amd64])\nConf curl (9)\n")
        self.assertEqual(plan.upgrades, ["curl"])
        self.assertFalse(plan.desktop or plan.kwin or plan.blocked)

    def test_plasma_needs_logging_out(self):
        plan = doctor.make_plan("Inst plasma-workspace [4:6.7.4] (4:6.7.5 Debian:testing)\n")
        self.assertTrue(plan.desktop)
        self.assertFalse(plan.kwin)

    def test_kwin_upgrade_rebuilds(self):
        plan = doctor.make_plan("Inst kwin-wayland [4:6.7.4] (4:6.7.5 Debian:testing)\n")
        self.assertTrue(plan.kwin and plan.desktop)

    def test_kwin_held_back_still_rebuilds(self):
        plan = doctor.make_plan("0 upgraded\n", kwin_update=True)
        self.assertTrue(plan.kwin)

    def test_pinned_effects_are_expected(self):
        plan = doctor.make_plan("Remv uzunyx-outline [0.2.1+kwin6.7.4]\nRemv uzunyx-genie [0.1.1+kwin6.7.4]\n")
        self.assertEqual(plan.expected, ["uzunyx-outline", "uzunyx-genie"])
        self.assertTrue(plan.kwin)
        self.assertFalse(plan.blocked or plan.needs_question)

    def test_our_other_packages_block(self):
        for name in ("uzunyx-editions", "tsunyx-launcher", "kora-icon-theme"):
            plan = doctor.make_plan(f"Remv {name} [1]\n")
            self.assertTrue(plan.blocked, name)

    def test_desktop_removal_blocks(self):
        for name in ("kwin-wayland", "plasma-workspace", "sddm", "systemd"):
            plan = doctor.make_plan(f"Remv {name} [1]\n")
            self.assertTrue(plan.blocked, name)

    def test_other_removal_asks(self):
        plan = doctor.make_plan("Remv libfoo1 [1]\n")
        self.assertTrue(plan.needs_question)
        self.assertFalse(plan.blocked)
        self.assertEqual(plan.others, ["libfoo1"])

    def test_conf_lines_are_ignored(self):
        plan = doctor.make_plan("Conf kwin-wayland (4:6.7.5)\n")
        self.assertEqual(plan.upgrades, [])


class Versions(unittest.TestCase):
    def test_upstream(self):
        self.assertEqual(doctor.upstream("4:6.7.4-2+b1"), "6.7.4")
        self.assertEqual(doctor.upstream("4:6.7.5-1"), "6.7.5")
        self.assertEqual(doctor.upstream("1.2.3"), "1.2.3")


class Translations(unittest.TestCase):
    def test_missing_text(self):
        import struct
        with tempfile.TemporaryDirectory() as tmp:
            key = b"ctx\x04Hello"
            value = b"Hola"
            start = 28 + 16
            data = struct.pack("<IIIIIII", 0x950412de, 0, 1, 28, 36, 0, 0)
            data += struct.pack("<II", len(key), start) + struct.pack("<II", len(value), start + len(key) + 1)
            data += key + b"\0" + value + b"\0"
            mo = os.path.join(tmp, "a.mo")
            with open(mo, "wb") as f:
                f.write(data)
            with open(os.path.join(tmp, "a.qml"), "w") as f:
                f.write('i18ndc(domain, "ctx", "Hello")\ni18ndc(page.domain, "ctx", "Gone")\n')
            self.assertEqual(doctor.missing_translations(tmp, mo), ["Gone"])


class Routine(unittest.TestCase):
    """The whole routine with apt and the terminal replaced: nothing runs."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.commands = []
        self.answers = []
        self.simulations = []
        self.versions = {"kwin-wayland": "4:6.7.4-2", "uzunyx-outline": "0.2.1+kwin6.7.4",
                         "uzunyx-openclose": "0.2.0+kwin6.7.4", "uzunyx-genie": "0.1.1+kwin6.7.4",
                         "kwin-dev": "4:6.7.4-2", "cmake": "3", "extra-cmake-modules": "6",
                         "libdrm-dev": "2", "pkgconf": "1"}
        self.candidate = "4:6.7.4-2"
        self.saved = {n: getattr(doctor, n) for n in
                      ("logged", "apt_sim", "ask", "all_checks", "check_modules", "check_grub", "build_all",
                       "installed_version", "candidate_version", "STATE_DIR", "STATE_FILE", "SOURCE", "take_snapshot")}
        doctor.logged = lambda command, log: self.commands.append(" ".join(command)) or True
        doctor.apt_sim = lambda: self.simulations.pop(0) if len(self.simulations) > 1 else self.simulations[0]
        doctor.ask = lambda question, default=False: self.answers.pop(0) if self.answers else default
        doctor.all_checks = lambda: []
        doctor.check_modules = lambda: []
        doctor.check_grub = lambda: []
        doctor.build_all = lambda log: []
        doctor.installed_version = lambda p: self.versions.get(p, "")
        doctor.candidate_version = lambda p: self.candidate
        doctor.take_snapshot = lambda log: self.commands.append("snapshot")
        doctor.STATE_DIR = self.tmp.name
        doctor.STATE_FILE = os.path.join(self.tmp.name, "state.json")
        doctor.SOURCE = self.tmp.name

    def tearDown(self):
        for name, value in self.saved.items():
            setattr(doctor, name, value)
        self.tmp.cleanup()

    def run_quiet(self):
        import contextlib
        import io
        with contextlib.redirect_stdout(io.StringIO()):
            return doctor.routine()

    def pending(self):
        return doctor.load_state().get("pending_after_login", False)

    def test_up_to_date_changes_nothing(self):
        self.simulations = ["0 upgraded\n"]
        self.assertEqual(self.run_quiet(), 0)
        self.assertEqual(self.commands, ["sudo apt-get update"])

    def test_ordinary_update_needs_no_login(self):
        self.simulations = ["Inst curl [8] (9)\n"]
        self.assertEqual(self.run_quiet(), 0)
        self.assertIn("sudo apt-get dist-upgrade -y", self.commands)
        self.assertFalse(self.pending())

    def test_plasma_update_waits_for_login(self):
        self.simulations = ["Inst plasma-desktop [1] (2)\n"]
        self.assertEqual(self.run_quiet(), 0)
        self.assertTrue(self.pending())

    def test_kwin_update_removes_upgrades_and_rebuilds_in_order(self):
        self.candidate = "4:6.7.5-1"
        self.simulations = ["Inst kwin-wayland [4:6.7.4] (4:6.7.5)\n"]
        self.assertEqual(self.run_quiet(), 0)
        joined = "\n".join(self.commands)
        self.assertLess(joined.index("snapshot"), joined.index("apt-get remove"))
        self.assertLess(joined.index("apt-get remove"), joined.index("dist-upgrade"))
        self.assertLess(joined.index("dist-upgrade"), joined.index("make -C"))
        self.assertIn("--reinstall", self.commands[-1])
        self.assertTrue(self.pending())

    def test_removing_our_package_stops_before_touching_anything(self):
        self.simulations = ["Remv uzunyx-editions [1]\nInst curl [8] (9)\n"]
        self.assertEqual(self.run_quiet(), 1)
        self.assertEqual(self.commands, ["sudo apt-get update"])

    def test_other_removal_refused(self):
        self.simulations = ["Remv libfoo1 [1]\n"]
        self.answers = [False]
        self.assertEqual(self.run_quiet(), 1)
        self.assertNotIn("sudo apt-get dist-upgrade -y", self.commands)

    def test_new_removal_after_taking_effects_out_restores_them(self):
        self.candidate = "4:6.7.5-1"
        self.simulations = ["Inst kwin-wayland [4:6.7.4] (4:6.7.5)\n", "Remv plasma-workspace [1]\n"]
        self.assertEqual(self.run_quiet(), 1)
        self.assertNotIn("sudo apt-get dist-upgrade -y", self.commands)
        self.assertIn("--reinstall", self.commands[-1])


if __name__ == "__main__":
    unittest.main()
