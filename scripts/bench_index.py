"""idx_review_movie_id(Q17) 를 만들기 전/후 실행 시간을 잰다. 결과는 results/bench_index.txt.

    uv run python scripts/bench_index.py            # 시드(78행) + 확장 데이터(리뷰 200,000행)
    uv run python scripts/bench_index.py --reviews 50000

* 시드 데이터는 78행이라 인덱스 효과가 측정 오차 안에 묻힌다. 그래서 같은 스키마에 가상 회원·영화·리뷰를
  더 넣은 "확장 데이터" 에서도 잰다(시드 행은 그대로 두고 뒤에 추가, 난수 시드 고정).
* 측정: 같은 쿼리를 여러 번 실행한 총 시간 → 1회 평균. 5번 반복해 중앙값을 쓴다.
* 실행 시간은 컴퓨터마다 다르다. 이 파일은 --check 비교 대상이 아니며(run_all.py 가 만들지 않음), 비율을 보는 용도다.

외부 라이브러리 없이 표준 라이브러리만 사용한다.
"""

import argparse
import platform
import random
import sqlite3
import statistics
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "results" / "bench_index.txt"
POINT = "SELECT rating, content FROM review WHERE movie_id = ?"
JOIN = ("SELECT m.title, AVG(r.rating) FROM movie AS m INNER JOIN review AS r ON r.movie_id = m.movie_id "
        "GROUP BY m.movie_id")


def build(path: Path) -> sqlite3.Connection:
    con = sqlite3.connect(str(path), isolation_level=None)
    con.execute("PRAGMA foreign_keys = ON")
    for name in ("01_schema.sql", "02_seed.sql"):
        con.executescript((ROOT / "sql" / name).read_text(encoding="utf-8"))
    con.execute("PRAGMA foreign_keys = ON")
    return con


def scale_up(con: sqlite3.Connection, reviews: int, members: int, movies: int) -> None:
    rng = random.Random(20261110)
    con.execute("BEGIN")
    con.executemany("INSERT INTO member (email, nickname, birth_year, joined_at) VALUES (?, ?, ?, '2024-01-01')",
                    [("bench{}@example.com".format(i), "bench{}".format(i), 1980 + i % 25) for i in range(members)])
    con.executemany("INSERT INTO movie (genre_id, title, release_date, running_time, country, director) "
                    "VALUES (?, ?, '2020-01-01', 120, '한국', '가상')",
                    [(1 + i % 9, "가상 영화 {}".format(i)) for i in range(movies)])
    member_ids = [r[0] for r in con.execute("SELECT member_id FROM member")]
    movie_ids = [r[0] for r in con.execute("SELECT movie_id FROM movie")]
    seen = set(con.execute("SELECT member_id, movie_id FROM review"))
    rows = []
    while len(rows) < reviews:
        pair = (rng.choice(member_ids), rng.choice(movie_ids))
        if pair in seen:
            continue
        seen.add(pair)
        rows.append(pair + (rng.randint(1, 5), "2024-{:02d}-{:02d} 12:00:00".format(rng.randint(1, 12), rng.randint(1, 28))))
    con.executemany("INSERT INTO review (member_id, movie_id, rating, created_at) VALUES (?, ?, ?, ?)", rows)
    con.execute("COMMIT")
    # ANALYZE 는 하지 않는다: 시드 DB · Q17 과 같은 조건(통계 없음)에서 계획을 비교하기 위해.
    # (통계가 있으면 인덱스 전에도 UNIQUE(member_id, movie_id) 인덱스를 skip-scan 으로 쓰는 계획이 나온다)


def timed(con: sqlite3.Connection, sql: str, params: list, repeat: int = 5) -> float:
    """params 목록을 한 번씩 실행한 시간의 1회 평균(ms), repeat 번 중 중앙값."""
    runs = []
    for _ in range(repeat):
        start = time.perf_counter()
        for p in params:
            con.execute(sql, p).fetchall()
        runs.append((time.perf_counter() - start) * 1000 / len(params))
    return statistics.median(runs)


def plan(con: sqlite3.Connection, sql: str) -> str:
    return " / ".join(row[3] for row in con.execute("EXPLAIN QUERY PLAN " + sql, (1,) if "?" in sql else ()))


def measure(con: sqlite3.Connection, label: str, point_runs: int) -> list:
    rng = random.Random(7)
    movie_ids = [r[0] for r in con.execute("SELECT movie_id FROM movie")]
    params = [(rng.choice(movie_ids),) for _ in range(point_runs)]
    n = con.execute("SELECT COUNT(*) FROM review").fetchone()[0]
    lines = ["[{}] review {:,}행 · movie {:,}편".format(label, n, len(movie_ids))]
    result = {}
    for state in ("before", "after"):
        if state == "after":
            con.execute("CREATE INDEX idx_review_movie_id ON review (movie_id)")
        result[state] = (timed(con, POINT, params), timed(con, JOIN, [()], repeat=5), plan(con, POINT), plan(con, JOIN))
    (pb, jb, ppb, jpb), (pa, ja, ppa, jpa) = result["before"], result["after"]
    lines += [
        "  영화 1편의 리뷰 조회 (WHERE movie_id = ?, {}회 평균)".format(point_runs),
        "    인덱스 전  {:9.4f} ms   계획: {}".format(pb, ppb),
        "    인덱스 후  {:9.4f} ms   계획: {}".format(pa, ppa),
        "    → {:.1f}배".format(pb / pa if pa else float("inf")),
        "  영화별 평균 (JOIN + GROUP BY, Q09 와 같은 형태, 1회)",
        "    인덱스 전  {:9.2f} ms   계획: {}".format(jb, jpb),
        "    인덱스 후  {:9.2f} ms   계획: {}".format(ja, jpa),
        "    → {:.1f}배".format(jb / ja if ja else float("inf")),
        "",
    ]
    return lines


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--reviews", type=int, default=200_000)
    ap.add_argument("--members", type=int, default=2_000)
    ap.add_argument("--movies", type=int, default=500)
    ap.add_argument("--point-runs", type=int, default=500)
    args = ap.parse_args()
    out = ["인덱스 벤치마크 — idx_review_movie_id (Q17) 생성 전/후 실행 시간",
           "생성: scripts/bench_index.py (이 파일은 --check 비교 대상이 아님, 시간은 컴퓨터마다 다름)",
           "환경: Python {} · SQLite {} · {}".format(platform.python_version(), sqlite3.sqlite_version, platform.machine()),
           "측정: 같은 쿼리를 반복 실행한 1회 평균, 5번 반복의 중앙값", ""]
    with tempfile.TemporaryDirectory() as tmp:
        con = build(Path(tmp) / "seed.db")
        out += measure(con, "시드 데이터", args.point_runs)
        con.close()
        con = build(Path(tmp) / "scaled.db")
        scale_up(con, args.reviews, args.members, args.movies)
        out += measure(con, "확장 데이터 (시드 + 가상 회원 {:,} · 영화 {:,} · 리뷰 {:,})".format(
            args.members, args.movies, args.reviews), args.point_runs)
        con.close()
    OUT.write_text("\n".join(out).rstrip() + "\n", encoding="utf-8")
    print("\n".join(out))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
