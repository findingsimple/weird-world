#!/usr/bin/env python3
"""Unit tests for scripts/new_game.py (stdlib unittest; run: python3 scripts/test_new_game.py)."""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import new_game


class DeriveNames(unittest.TestCase):
    def test_multi_word(self) -> None:
        n = new_game.derive_names("Space Rocks 2")
        self.assertEqual(n["pascal"], "SpaceRocks2")
        self.assertEqual(n["snake"], "space_rocks_2")
        self.assertEqual(n["kebab"], "space-rocks-2")
        self.assertEqual(n["flat"], "spacerocks2")

    def test_single_word_keeps_case_in_pascal(self) -> None:
        self.assertEqual(new_game.derive_names("Rocks")["pascal"], "Rocks")


class Validate(unittest.TestCase):
    def test_rejects_control_characters(self) -> None:
        with self.assertRaises(new_game.InvalidInput):
            new_game.validate("Ok", "a/b", "line1\nconfig/x=1", None)

    def test_rejects_quote_in_description(self) -> None:
        with self.assertRaises(new_game.InvalidInput):
            new_game.validate("Ok", "a/b", 'say "hi"', None)

    def test_rejects_bad_repo_and_bundle(self) -> None:
        with self.assertRaises(new_game.InvalidInput):
            new_game.validate("Ok", "no-slash", None, None)
        with self.assertRaises(new_game.InvalidInput):
            new_game.validate("Ok", "a/b", None, "notreversedns")

    def test_accepts_typical_values(self) -> None:
        new_game.validate(
            "Space Rocks", "you/space-rocks", "Blast asteroids.", "com.you.spacerocks"
        )


class Replacements(unittest.TestCase):
    def setUp(self) -> None:
        self.pairs = new_game.replacements(
            new_game.derive_names("Space Rocks"),
            "you/space-rocks",
            "com.you.spacerocks",
        )

    def test_readme_title_badges_and_pages_link(self) -> None:
        text = (
            "# game-scaffolding\n"
            "[![CI](https://github.com/findingsimple/game-scaffolding/actions/workflows/ci.yml/badge.svg)]\n"
            "**Play:** <https://findingsimple.github.io/game-scaffolding/>\n"
            "cd game-scaffolding\n"
        )
        out, count = new_game.apply(text, self.pairs)
        self.assertNotIn("game-scaffolding", out)
        self.assertNotIn("findingsimple", out)
        self.assertIn("# space-rocks", out)
        self.assertIn("https://you.github.io/space-rocks/", out)
        self.assertIn("github.com/you/space-rocks/actions", out)
        self.assertEqual(count, 4)

    def test_example_identifiers_and_bundle_id(self) -> None:
        text = 'config/name="Coin Dash"\nbundle="com.findingsimple.coindash"\nclass CoinDash coin_dash coin-dash coindash\n'
        out, count = new_game.apply(text, self.pairs)
        for token in (
            "Coin Dash",
            "CoinDash",
            "coin_dash",
            "coin-dash",
            "coindash",
            "findingsimple",
        ):
            self.assertNotIn(token, out)
        self.assertIn('config/name="Space Rocks"', out)
        self.assertIn('bundle="com.you.spacerocks"', out)
        self.assertEqual(count, 6)

    def test_count_is_zero_when_nothing_matches(self) -> None:
        out, count = new_game.apply("nothing to do here", self.pairs)
        self.assertEqual((out, count), ("nothing to do here", 0))


if __name__ == "__main__":
    unittest.main(verbosity=1)
