"""제출 요구사항 자동 검증: 스키마 구조, 제약조건 동작, 샘플 데이터, 쿼리 구성.

    python -m unittest discover -s tests -t . -v
"""

import re
import sqlite3
import sys
import unittest
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import run_all  # noqa: E402


def fresh_db() -> sqlite3.Connection:
    con = sqlite3.connect(":memory:", isolation_level=None)
    con.execute("PRAGMA foreign_keys = ON")
    for name in run_all.BUILD_FILES:
        con.executescript((run_all.SQL_DIR / name).read_text(encoding="utf-8"))
    return con


class SchemaTest(unittest.TestCase):
    def setUp(self):
        self.con = fresh_db()

    def test_at_least_four_tables_each_with_primary_key(self):
        tables = [r[0] for r in self.con.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")]
        self.assertGreaterEqual(len(tables), 4)
        for table in tables:
            pk = [r for r in self.con.execute("PRAGMA table_info({})".format(table)) if r[5]]
            with self.subTest(table=table):
                self.assertTrue(pk, "PK 없음")

    def test_at_least_two_foreign_keys_forming_one_to_many(self):
        fks = []
        for (table,) in self.con.execute("SELECT name FROM sqlite_master WHERE type='table'"):
            fks += [(table, r[3], r[2], r[4]) for r in self.con.execute("PRAGMA foreign_key_list({})".format(table))]
        self.assertGreaterEqual(len(fks), 2)
        self.assertIn(("movie", "genre_id", "genre", "genre_id"), fks)
        self.assertIn(("review", "member_id", "member", "member_id"), fks)
        self.assertIn(("review", "movie_id", "movie", "movie_id"), fks)

    def test_not_null_and_unique_constraints_exist(self):
        not_null = [(t, r[1]) for t in run_all.TABLES for r in self.con.execute("PRAGMA table_info({})".format(t)) if r[3]]
        self.assertGreaterEqual(len(not_null), 1)
        uniques = [r for t in run_all.TABLES for r in self.con.execute("PRAGMA index_list({})".format(t)) if r[2]]
        self.assertGreaterEqual(len(uniques), 1)

    def test_every_table_has_at_least_ten_rows(self):
        for table in run_all.TABLES:
            with self.subTest(table=table):
                self.assertGreaterEqual(self.con.execute("SELECT COUNT(*) FROM {}".format(table)).fetchone()[0], 10)

    def test_seed_data_has_no_dangling_references(self):
        self.assertEqual(self.con.execute("PRAGMA foreign_key_check").fetchall(), [])


class ConstraintBehaviourTest(unittest.TestCase):
    """없는 값 참조가 실제로 막히는지, CHECK·UNIQUE·NOT NULL 이 동작하는지."""

    def setUp(self):
        self.con = fresh_db()

    def assertRejected(self, sql, fragment):
        with self.assertRaises(sqlite3.IntegrityError) as cm:
            self.con.execute(sql)
        self.assertIn(fragment, str(cm.exception))

    def test_foreign_keys_block_missing_parent(self):
        self.assertRejected("INSERT INTO review (member_id, movie_id, rating, created_at) VALUES (999, 1, 5, '2024-10-01 10:00:00')",
                            "FOREIGN KEY")
        self.assertRejected("INSERT INTO movie (genre_id, title, release_date, running_time, country, director) "
                            "VALUES (99, 'x', '2024-01-01', 90, '한국', 'x')", "FOREIGN KEY")

    def test_restrict_and_cascade(self):
        self.assertRejected("DELETE FROM genre WHERE genre_id = 1", "FOREIGN KEY")
        before = self.con.execute("SELECT COUNT(*) FROM review WHERE member_id = 15").fetchone()[0]
        self.assertEqual(before, 2)
        self.con.execute("DELETE FROM member WHERE member_id = 15")
        self.assertEqual(self.con.execute("SELECT COUNT(*) FROM review WHERE member_id = 15").fetchone()[0], 0)

    def test_check_unique_not_null(self):
        self.assertRejected("UPDATE review SET rating = 0 WHERE review_id = 1", "CHECK")
        self.assertRejected("UPDATE movie SET release_date = '2024-02-30' WHERE movie_id = 1", "CHECK")
        self.assertRejected("UPDATE review SET created_at = '2024-13-01 00:00:00' WHERE review_id = 1", "CHECK")
        self.assertRejected("UPDATE member SET joined_at = '2024-13-01' WHERE member_id = 1", "CHECK")  # '=' 였다면 통과됨
        self.assertRejected("UPDATE member SET joined_at = '2024/01/01' WHERE member_id = 1", "CHECK")
        self.assertRejected("INSERT INTO review (member_id, movie_id, rating, created_at) "
                            "SELECT member_id, movie_id, 3, created_at FROM review WHERE review_id = 1", "UNIQUE")
        self.assertRejected("UPDATE member SET email = NULL WHERE member_id = 1", "NOT NULL")

    def test_foreign_keys_are_off_without_pragma(self):
        """SQLite 는 연결마다 PRAGMA 를 켜야 한다 — 끄면 고아 행이 들어간다는 것을 확인."""
        con = sqlite3.connect(":memory:")
        con.executescript((run_all.SQL_DIR / "01_schema.sql").read_text(encoding="utf-8"))
        con.execute("PRAGMA foreign_keys = OFF")
        con.execute("INSERT INTO review (member_id, movie_id, rating, created_at) VALUES (1, 1, 5, '2024-10-01 10:00:00')")
        # 빈 DB 라 member 와 movie 두 부모가 모두 없다 → 위반 2건
        self.assertEqual(len(con.execute("PRAGMA foreign_key_check").fetchall()), 2)


class QueryFileTest(unittest.TestCase):
    """03_queries.sql 이 과제의 범주별 최소 개수를 채우는지 SQL 문을 분석해 검사한다."""

    @classmethod
    def setUpClass(cls):
        _, cls.blocks = run_all.parse_blocks(run_all.SQL_DIR / "03_queries.sql")

    def test_at_least_fifteen_queries_with_description(self):
        self.assertGreaterEqual(len(self.blocks), 15)
        for block in self.blocks:
            with self.subTest(q=block.qid):
                self.assertTrue(block.title.strip())

    def test_category_minimums(self):
        sql = {b.qid: " ".join(s.sql.upper() for s in b.statements) for b in self.blocks}
        cats = Counter(b.category.split()[0] for b in self.blocks)
        self.assertGreaterEqual(cats["기본"], 4)
        self.assertGreaterEqual(cats["조인"], 4)
        self.assertGreaterEqual(cats["집계"], 3)
        self.assertGreaterEqual(cats["서브쿼리"], 1)
        self.assertGreaterEqual(cats["수정"] + cats["삭제"], 2)
        self.assertGreaterEqual(cats["인덱스"], 1)

        basic = [q for b, q in sql.items() if b in {x.qid for x in self.blocks if x.category.startswith("기본")}]
        self.assertTrue(all("WHERE" in q and "ORDER BY" in q for q in basic))
        self.assertTrue(any("LIMIT" in q for q in basic))
        all_sql = " ".join(sql.values())
        self.assertGreaterEqual(len(re.findall(r"INNER JOIN", all_sql)), 2)
        self.assertGreaterEqual(len(re.findall(r"LEFT JOIN", all_sql)), 1)
        self.assertGreaterEqual(sum(1 for f in ("COUNT(", "SUM(", "AVG(") if f in all_sql), 2)
        self.assertIn("GROUP BY", all_sql)
        self.assertRegex(all_sql, r"\(\s*SELECT")
        self.assertIn("UPDATE ", all_sql)
        self.assertIn("DELETE FROM", all_sql)
        self.assertIn("CREATE INDEX", all_sql)

    def test_required_fifteen_match_categories(self):
        """과제 필수 15개(분류에 '추가' 가 없는 쿼리)는 범주별 개수가 요구와 정확히 같고, 추가분은 Q12 · Q14 뿐이다."""
        required = [b for b in self.blocks if "추가" not in b.category]
        extra = [b.qid for b in self.blocks if "추가" in b.category]
        self.assertEqual(len(required), 15)
        self.assertEqual(extra, ["Q12", "Q14"])
        cats = Counter(b.category.split()[0] for b in required)
        self.assertEqual(dict(cats), {"기본": 4, "조인": 4, "집계": 3, "서브쿼리": 1, "수정": 1, "삭제": 1, "인덱스": 1})

    def test_every_query_has_screenshot(self):
        """Q01~Q17 모두 sqlite3 CLI 실행 화면(results/screenshots/Qnn.png)이 있고 결과 파일에서 연결된다."""
        for block in self.blocks:
            with self.subTest(q=block.qid):
                self.assertTrue((run_all.SCREENSHOT_DIR / "{}.png".format(block.qid)).is_file())
                head = (run_all.RESULTS_DIR / "{}.txt".format(block.qid)).read_text(encoding="utf-8").splitlines()[:3]
                self.assertIn("screenshot: results/screenshots/{}.png (sqlite3 CLI 실행 화면)".format(block.qid), head)

    def test_all_sql_files_execute_and_results_are_current(self):
        self.assertEqual(run_all.main(["--check"]), 0)


if __name__ == "__main__":
    unittest.main()
