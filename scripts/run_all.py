"""SQL 파일을 순서대로 실행해 DB 를 만들고, 쿼리마다 실행 결과를 results/ 에 텍스트로 저장한다.

    python scripts/run_all.py            # movie_review.db 생성 + results/ 갱신
    python scripts/run_all.py --check    # results/ 가 SQL 과 일치하는지 검사 (CI 용, 파일은 바꾸지 않음)

SQL 파일 규칙
* ``-- @Q01 | 분류 | 설명`` 줄이 결과 블록 하나의 시작이다. 블록 안에는 SQL 문이 여러 개 있을 수 있다.
* 문장 바로 위의 일반 주석(``-- 변경 전: …``)은 그 문장의 설명으로 함께 출력한다.
* ``-- @expect-error`` 가 붙은 문장은 실패해야 정상이다(보너스: 정합성 깨뜨려 보기). 성공하면 스크립트가 실패한다.

외부 라이브러리 없이 표준 라이브러리 ``sqlite3`` 만 사용한다.
"""

import argparse
import re
import sqlite3
import sys
import tempfile
import unicodedata
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Optional, Sequence, Tuple

ROOT = Path(__file__).resolve().parents[1]
SQL_DIR = ROOT / "sql"
RESULTS_DIR = ROOT / "results"
SCREENSHOT_DIR = RESULTS_DIR / "screenshots"   # sqlite3 CLI 실행 화면 (있으면 결과 파일에 경로를 남긴다)
DB_PATH = ROOT / "movie_review.db"

BUILD_FILES = ("01_schema.sql", "02_seed.sql")
QUERY_FILES = ("03_queries.sql", "04_bonus_join_vs_subquery.sql", "05_bonus_integrity.sql",
               "06_bonus_mini_report.sql")
TABLES = ("genre", "member", "movie", "review")

MARKER = re.compile(r"^--\s*@(?P<id>[A-Z]+\d+)\s*\|\s*(?P<category>[^|]+?)\s*\|\s*(?P<title>.+?)\s*$")
EXPECT_ERROR = "-- @expect-error"


# ============================================================================ SQL 파싱
@dataclass
class Statement:
    sql: str
    caption: List[str] = field(default_factory=list)
    expect_error: bool = False


@dataclass
class Block:
    qid: str
    category: str
    title: str
    source: str
    statements: List[Statement] = field(default_factory=list)

    @property
    def slug(self) -> str:
        return self.qid


def parse_blocks(path: Path) -> Tuple[List[Statement], List[Block]]:
    """(블록 앞 문장들, 블록 목록). 블록 앞 문장은 PRAGMA 처럼 결과가 필요 없는 준비 문장이다."""
    preamble: List[Statement] = []
    blocks: List[Block] = []
    buffer: List[str] = []
    caption: List[str] = []
    expect_error = False

    def target() -> List[Statement]:
        return blocks[-1].statements if blocks else preamble

    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.rstrip()
        stripped = line.strip()
        if not buffer:
            match = MARKER.match(stripped)
            if match:
                blocks.append(Block(match["id"], match["category"], match["title"], path.name))
                caption, expect_error = [], False
                continue
            if stripped == EXPECT_ERROR:
                expect_error = True
                continue
            if stripped.startswith("--") or not stripped:
                if stripped.startswith("--") and blocks and not stripped.startswith("-- ===") and not stripped.startswith("-- ---"):
                    caption.append(stripped[2:].strip())
                elif not stripped:
                    pass
                continue
        buffer.append(line)
        joined = "\n".join(buffer)
        if sqlite3.complete_statement(joined):
            target().append(Statement(joined.strip(), caption, expect_error))
            buffer, caption, expect_error = [], [], False
    if "\n".join(buffer).strip():
        raise SystemExit("{}: 세미콜론으로 끝나지 않은 SQL 이 있습니다".format(path.name))
    return preamble, blocks


# ============================================================================ 결과 포맷
def width(text: str) -> int:
    return sum(0 if unicodedata.combining(ch) else 2 if unicodedata.east_asian_width(ch) in "WF" else 1 for ch in text)


def cell(value) -> str:
    if value is None:
        return "NULL"
    if isinstance(value, float):
        return "{:g}".format(round(value, 4))
    return str(value)


def text_table(columns: Sequence[str], rows: Sequence[Sequence]) -> List[str]:
    cells = [[cell(v) for v in row] for row in rows]
    numeric = [all(isinstance(row[i], (int, float)) or row[i] is None for row in rows) and rows for i in range(len(columns))]
    widths = [max([width(c)] + [width(r[i]) for r in cells]) for i, c in enumerate(columns)]

    def fmt(values: Sequence[str]) -> str:
        parts = []
        for i, v in enumerate(values):
            gap = " " * (widths[i] - width(v))
            parts.append(gap + v if numeric[i] else v + gap)
        return " | ".join(parts).rstrip()

    lines = [fmt(columns), "-+-".join("-" * w for w in widths)]
    lines += [fmt(r) for r in cells]
    return lines


def md_escape(text: str) -> str:
    return text.replace("|", "\\|").replace("\n", " ")


def markdown_table(columns: Sequence[str], rows: Sequence[Sequence]) -> List[str]:
    lines = ["| " + " | ".join(md_escape(c) for c in columns) + " |"]
    aligns = ["---:" if rows and all(isinstance(r[i], (int, float)) or r[i] is None for r in rows) else "---"
              for i in range(len(columns))]
    lines.append("| " + " | ".join(aligns) + " |")
    for row in rows:
        lines.append("| " + " | ".join(md_escape(cell(v)) for v in row) + " |")
    return lines


def query_plan(rows: Sequence[Sequence]) -> List[str]:
    """EXPLAIN QUERY PLAN 결과(id, parent, notused, detail)를 sqlite3 CLI 와 같은 트리로 그린다."""
    children = {}
    for node_id, parent, _unused, detail in rows:
        children.setdefault(parent, []).append((node_id, detail))
    lines = ["QUERY PLAN"]

    def walk(parent: int, prefix: str) -> None:
        items = children.get(parent, [])
        for i, (node_id, detail) in enumerate(items):
            last = i == len(items) - 1
            lines.append(prefix + ("`--" if last else "|--") + detail)
            walk(node_id, prefix + ("   " if last else "|  "))

    walk(0, "")
    return lines


@dataclass
class Outcome:
    statement: Statement
    columns: Optional[List[str]] = None
    rows: Optional[List[tuple]] = None
    affected: Optional[int] = None
    error: Optional[str] = None
    plan: bool = False


def execute(con: sqlite3.Connection, stmt: Statement, source: str) -> Outcome:
    try:
        cur = con.execute(stmt.sql)
        rows = cur.fetchall()
    except sqlite3.Error as exc:
        if stmt.expect_error:
            return Outcome(stmt, error="{}: {}".format(type(exc).__name__, exc))
        raise SystemExit("[실패] {}\n{}\n→ {}".format(source, stmt.sql, exc))
    if stmt.expect_error:
        raise SystemExit("[실패] 오류가 나야 하는 문장이 성공했습니다 ({}):\n{}".format(source, stmt.sql))
    if cur.description is not None:
        columns = [d[0] for d in cur.description]
        is_plan = stmt.sql.upper().startswith("EXPLAIN QUERY PLAN")
        return Outcome(stmt, columns, rows, plan=is_plan)
    return Outcome(stmt, affected=cur.rowcount if cur.rowcount >= 0 else None)


def screenshot(block: Block) -> Optional[str]:
    """results/screenshots/<ID>.png 가 있으면 results/ 기준 상대 경로를 돌려준다 (--check 의 임시 폴더와 무관하게 같은 값)."""
    name = "{}.png".format(block.qid)
    return "screenshots/" + name if (SCREENSHOT_DIR / name).exists() else None


def render_text(block: Block, outcomes: List[Outcome]) -> str:
    out = ["{} [{}] {}".format(block.qid, block.category, block.title), "source: sql/{}".format(block.source)]
    if screenshot(block):
        out.append("screenshot: results/{} (sqlite3 CLI 실행 화면)".format(screenshot(block)))
    out.append("")
    for o in outcomes:
        for line in o.statement.caption:
            out.append("-- " + line)
        out.append("sqlite> " + o.statement.sql.replace("\n", "\n   ...> "))
        if o.error is not None:
            out.append("Error (예상된 오류): " + o.error.split(": ", 1)[1])
        elif o.plan:
            out += query_plan(o.rows)
        elif o.columns is not None:
            out += text_table(o.columns, o.rows)
            out.append("({} row{})".format(len(o.rows), "" if len(o.rows) == 1 else "s"))
        else:
            out.append("OK" + ("" if o.affected is None else " ({} row{} affected)".format(o.affected, "" if o.affected == 1 else "s")))
        out.append("")
    return "\n".join(out).rstrip() + "\n"


def render_markdown(block: Block, outcomes: List[Outcome]) -> List[str]:
    out = ["### {} · {}".format(block.qid, block.title), "", "`{}` · 원본: [`sql/{}`](../sql/{})".format(
        block.category, block.source, block.source), ""]
    if screenshot(block):
        out += ["실행 화면 (sqlite3 CLI): [`{0}`]({0})".format(screenshot(block)), "",
                "![{} 실행 화면]({})".format(block.qid, screenshot(block)), ""]
    for o in outcomes:
        if o.statement.caption:
            out.append("_" + " ".join(o.statement.caption) + "_")
            out.append("")
        out += ["```sql", o.statement.sql, "```", ""]
        if o.error is not None:
            out += ["```text", "Error (예상된 오류): " + o.error.split(": ", 1)[1], "```", ""]
        elif o.plan:
            out += ["```text"] + query_plan(o.rows) + ["```", ""]
        elif o.columns is not None:
            out += markdown_table(o.columns, o.rows)
            out += ["", "({} row{})".format(len(o.rows), "" if len(o.rows) == 1 else "s"), ""]
        else:
            out += ["`OK" + ("" if o.affected is None else " ({} rows affected)".format(o.affected)) + "`", ""]
    return out


# ============================================================================ 실행
def build(db_path: Path) -> sqlite3.Connection:
    if db_path.exists():
        db_path.unlink()
    con = sqlite3.connect(str(db_path), isolation_level=None)  # autocommit: SQL 파일의 BEGIN/COMMIT 을 그대로 따른다
    con.execute("PRAGMA foreign_keys = ON")
    for name in BUILD_FILES:
        con.executescript((SQL_DIR / name).read_text(encoding="utf-8"))
        con.execute("PRAGMA foreign_keys = ON")  # executescript 이후에도 연결 설정 유지 확인
    return con


def summary_lines(con: sqlite3.Connection) -> Tuple[List[str], List[Tuple[str, int]], int]:
    lines = ["00 [검증] 테이블별 행 수와 FK 무결성 (02_seed.sql 직후)", "", "sqlite> SELECT …;"]
    rows = [(t, con.execute("SELECT COUNT(*) FROM {}".format(t)).fetchone()[0]) for t in TABLES]
    lines += text_table(["table", "rows"], rows)
    fk = con.execute("PRAGMA foreign_key_check").fetchall()
    lines += ["", "sqlite> PRAGMA foreign_key_check;", "(위반 {}건)".format(len(fk)),
              "", "sqlite> PRAGMA foreign_keys;", str(con.execute("PRAGMA foreign_keys").fetchone()[0]),
              "", "SQLite " + sqlite3.sqlite_version]
    return lines, rows, len(fk)


def generate(out_dir: Path, db_path: Path) -> List[str]:
    """SQL 파일마다 새 DB 를 만들어 실행한다(03 의 UPDATE/DELETE 가 보너스 파일 결과에 영향을 주지 않도록)."""
    con = build(db_path)
    out_dir.mkdir(parents=True, exist_ok=True)
    summary, counts, fk_violations = summary_lines(con)
    (out_dir / "00_table_counts.txt").write_text("\n".join(summary) + "\n", encoding="utf-8")
    assert all(n >= 10 for _, n in counts), counts
    assert fk_violations == 0

    md = ["# 실행 결과", "",
          "`python scripts/run_all.py` 가 빈 DB 에 `01_schema.sql` → `02_seed.sql` 을 실행한 뒤, 아래 쿼리를 **순서대로** 실행한 실제 결과입니다.",
          "쿼리별 텍스트 결과(sqlite3 CLI 형식)는 같은 폴더의 `Qnn.txt` · `Bnn.txt` 파일에, Q01~Q17 의 sqlite3 CLI 실행 화면은 [`screenshots/`](screenshots/README.md) 에 있습니다.", "",
          "- SQLite {}".format(sqlite3.sqlite_version),
          "- 테이블 행 수: " + ", ".join("{} {}".format(t, n) for t, n in counts) + " (모두 10행 이상)",
          "- `PRAGMA foreign_key_check` 위반 0건", ""]
    index = ["| ID | 분류 | 내용 | 결과 파일 | 실행 화면 |", "| --- | --- | --- | --- | --- |"]
    sections: List[str] = []
    written = ["00_table_counts.txt"]
    try:
        for name in QUERY_FILES:
            con.close()
            con = build(db_path)
            preamble, blocks = parse_blocks(SQL_DIR / name)
            for stmt in preamble:
                execute(con, stmt, name)
            for block in blocks:
                outcomes = [execute(con, stmt, "{} {}".format(name, block.qid)) for stmt in block.statements]
                filename = "{}.txt".format(block.slug)
                (out_dir / filename).write_text(render_text(block, outcomes), encoding="utf-8")
                written.append(filename)
                shot = screenshot(block)
                index.append("| [{0}](#{1}) | {2} | {3} | [{4}]({4}) | {5} |".format(
                    block.qid, anchor(block), block.category, md_escape(block.title), filename,
                    "[{0}]({1})".format(shot.split("/")[-1], shot) if shot else "-"))
                sections += render_markdown(block, outcomes)
    finally:
        con.close()  # 실패해도 DB 파일을 닫아야 Windows 에서 임시 폴더를 지울 수 있다
    md += ["## 목차", ""] + index + ["", "## 결과", ""] + sections
    (out_dir / "README.md").write_text("\n".join(md).rstrip() + "\n", encoding="utf-8")
    written.append("README.md")
    return written


def anchor(block: Block) -> str:
    """GitHub 마크다운 제목 앵커 규칙(소문자, 공백→-, 구두점 제거)."""
    text = "{} · {}".format(block.qid, block.title).lower()
    text = re.sub(r"[^\w\- ]", "", text)
    return text.replace(" ", "-")


def normalize(text: str) -> str:
    """버전 줄처럼 환경마다 달라지는 부분을 지운다."""
    return "\n".join(line for line in text.splitlines() if not line.startswith("SQLite "))


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--check", action="store_true", help="results/ 가 최신인지 검사만 한다")
    args = parser.parse_args(argv)
    if args.check:
        with tempfile.TemporaryDirectory() as tmp:
            files = generate(Path(tmp) / "results", Path(tmp) / "check.db")
            stale, skipped = [], []
            for f in files:
                fresh = (Path(tmp) / "results" / f).read_text(encoding="utf-8")
                saved = (RESULTS_DIR / f).read_text(encoding="utf-8") if (RESULTS_DIR / f).exists() else None
                if f == "README.md" or "QUERY PLAN" in fresh:
                    skipped.append(f)  # 실행 계획 문구는 SQLite 버전마다 달라서 비교하지 않는다
                    continue
                if saved is None or normalize(saved) != normalize(fresh):
                    stale.append(f)
        if stale:
            print("[실패] results/ 가 SQL 실행 결과와 다릅니다. python scripts/run_all.py 로 다시 생성하세요: " + ", ".join(stale))
            return 1
        print("[통과] results/ 의 {}개 파일이 SQL 실행 결과와 일치합니다 (실행 계획 포함 {}개는 버전 차이로 비교 제외: {}).".format(
            len(files) - len(skipped), len(skipped), ", ".join(skipped)))
        return 0
    files = generate(RESULTS_DIR, DB_PATH)
    print("[완료] {} 생성, results/ 에 {}개 파일 기록".format(DB_PATH.name, len(files)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
