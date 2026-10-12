# 보너스 과제 ③ — 미니 리포트: 핵심 지표 3개

📂 최종 SQL: [`sql/06_bonus_mini_report.sql`](../sql/06_bonus_mini_report.sql) · 📄 결과: [`results/R01.txt`](../results/R01.txt), [`R02.txt`](../results/R02.txt), [`R03.txt`](../results/R03.txt)

영화 평점 서비스를 운영한다면 매주 확인할 질문 세 가지를 정하고, 각각을 SQL 한 문장으로 구했습니다.

| 지표 | 운영 질문 | 쓰는 곳 |
| --- | --- | --- |
| 1. 월별 리뷰 활동 추이 | 서비스가 살아 있는가? 사용자 만족도는? | 월간 리포트, 이벤트 효과 측정 |
| 2. 인기 영화 TOP 10 (가중 평점) | 첫 화면에 무엇을 추천할까? | 메인 추천 영역 |
| 3. 장르별 만족도 | 어떤 장르가 강하고 약한가? | 콘텐츠 수급·큐레이션 |

> 샘플 데이터는 78건의 가상 리뷰라 수치 자체보다 **지표를 어떻게 정의하고 읽는지** 를 보여주는 것이 목적입니다.

## 지표 1. 월별 리뷰 활동 추이

```sql
SELECT strftime('%Y-%m', created_at)                                          AS month,
       COUNT(*)                                                               AS reviews,
       COUNT(DISTINCT member_id)                                              AS active_reviewers,
       ROUND(AVG(rating), 2)                                                  AS avg_rating,
       ROUND(100.0 * SUM(CASE WHEN rating >= 4 THEN 1 ELSE 0 END) / COUNT(*), 1) AS positive_pct
FROM review
GROUP BY month
ORDER BY month;
```

| month | reviews | active_reviewers | avg_rating | positive_pct |
| --- | ---: | ---: | ---: | ---: |
| 2024-01 | 12 | 11 | 4.25 | 91.7 |
| 2024-02 | 9 | 9 | 4.22 | 88.9 |
| 2024-03 | 7 | 7 | 4.29 | 85.7 |
| 2024-04 | 12 | 12 | 3.83 | 66.7 |
| 2024-05 | 9 | 7 | 3.67 | 55.6 |
| 2024-06 | 9 | 9 | 4.44 | 100 |
| 2024-07 | 6 | 5 | 4.33 | 83.3 |
| 2024-08 | 7 | 7 | 4 | 85.7 |
| 2024-09 | 7 | 7 | 4.71 | 100 |

**읽는 법**
- `reviews` 와 `active_reviewers` 를 같이 봐야 합니다. 리뷰 수가 같아도 소수 회원이 몰아 쓴 것인지, 많은 회원이 고르게 쓴 것인지가 다릅니다.
- **4~5월에 평균 별점과 호평률(4점 이상 비율)이 떨어졌습니다.** 원리뷰를 보면 4월에는 3점 이하 리뷰가 4건(극한직업·범죄도시·라라랜드·곤지암) 몰렸고, 5월에는 리뷰 9건 중 4건이 공포 영화(곤지암·파묘)였습니다. 공포는 지표 3에서 호평률 33.3% 로 가장 낮은 장르라, 평균만 보면 "서비스 만족도 하락" 으로 오해할 수 있습니다. 월별 지표는 **그 달에 어떤 영화가 리뷰됐는지**(장르 구성)와 함께 읽어야 합니다.
- 7월 이후 리뷰 수가 줄어든 것은 Q15 에서 휴면 전환된 회원(공포체험·가족나들이 등)의 활동이 5월에 끝난 것과 맞물립니다. 활동 회원 수가 줄어드는 추세는 재방문 유도 알림 같은 대응의 근거가 됩니다.

## 지표 2. 인기 영화 TOP 10 — 베이지안 가중 평점

단순 평균으로 랭킹을 매기면 **리뷰가 적은 영화가 우연히 위로 올라갑니다.** 리뷰 2개가 모두 5점이면 평균 5.0 으로, 리뷰 7개에 평균 4.71 인 영화를 이깁니다.
그래서 IMDb 등이 쓰는 가중 평점 공식으로 "리뷰가 적을수록 전체 평균 쪽으로 끌어당기도록" 보정했습니다.

```
가중 평점 = (v × R + m × C) / (v + m)
  v = 그 영화의 리뷰 수      R = 그 영화의 평균 별점
  C = 전체 평균 별점(4.17)   m = 최소 신뢰 리뷰 수 (3)
```

리뷰가 m 개 있는 영화는 자기 평균과 전체 평균을 반반 섞고, 리뷰가 많아질수록 자기 평균에 가까워집니다.

```sql
WITH overall AS (SELECT AVG(rating) AS c, 3 AS m FROM review),
     per_movie AS (SELECT movie_id, COUNT(*) AS v, AVG(rating) AS r FROM review GROUP BY movie_id)
SELECT mv.title, pm.v AS review_count, ROUND(pm.r, 2) AS avg_rating,
       ROUND((pm.v * pm.r + o.m * o.c) / (pm.v + o.m), 3) AS weighted_score
FROM per_movie pm
JOIN movie mv ON mv.movie_id = pm.movie_id
CROSS JOIN overall o
ORDER BY weighted_score DESC, review_count DESC, mv.title
LIMIT 10;
```

| 순위 | title | review_count | avg_rating | weighted_score |
| ---: | --- | ---: | ---: | ---: |
| 1 | 기생충 | 7 | 4.71 | 4.55 |
| 2 | 인터스텔라 | 6 | 4.67 | 4.5 |
| 3 | 서울의 봄 | 4 | 4.75 | 4.5 |
| 4 | 듄: 파트 2 | 3 | 4.67 | 4.417 |
| 5 | 너의 이름은. | 4 | 4.5 | 4.357 |
| 6 | 비긴 어게인 | 2 | 4.5 | 4.3 |
| 7 | 올드보이 | 2 | 4.5 | 4.3 |
| 8 | 인사이드 아웃 2 | 2 | 4.5 | 4.3 |
| 9 | 겟 아웃 | 3 | 4.33 | 4.25 |
| 10 | 엘리멘탈 | 3 | 4.33 | 4.25 |

**읽는 법**
- 단순 평균 1위는 **서울의 봄(4.75, 리뷰 4개)** 이지만(Q09), 가중 평점 1위는 **기생충(4.71, 리뷰 7개)** 입니다. 평균은 비슷한데 근거가 되는 리뷰가 더 많은 쪽을 더 신뢰한 결과입니다.
- 리뷰 2개짜리 영화들(비긴 어게인, 올드보이, 인사이드 아웃 2)은 평균 4.5 지만 4.3 으로 내려와, 리뷰 4개인 너의 이름은.(4.357) 아래에 놓였습니다.
- `m` 값이 클수록 보수적인 랭킹이 됩니다. 서비스 규모가 커지면 m 을 "영화당 리뷰 수의 중앙값" 정도로 올리는 것이 일반적입니다.

## 지표 3. 장르별 만족도

```sql
SELECT g.name AS genre,
       COUNT(r.review_id) AS reviews,
       ROUND(AVG(r.rating), 2) AS avg_rating,
       ROUND(100.0 * SUM(CASE WHEN r.rating >= 4 THEN 1 ELSE 0 END) / COUNT(r.review_id), 1) AS positive_pct,
       ROUND(100.0 * SUM(CASE WHEN r.rating <= 2 THEN 1 ELSE 0 END) / COUNT(r.review_id), 1) AS negative_pct
FROM genre g
JOIN movie m  ON m.genre_id = g.genre_id
JOIN review r ON r.movie_id = m.movie_id
GROUP BY g.genre_id, g.name
ORDER BY positive_pct DESC, reviews DESC;
```

| genre | reviews | avg_rating | positive_pct | negative_pct |
| --- | ---: | ---: | ---: | ---: |
| 드라마 | 11 | 4.73 | 100 | 0 |
| 애니메이션 | 9 | 4.44 | 100 | 0 |
| SF | 9 | 4.67 | 100 | 0 |
| 스릴러 | 8 | 4.25 | 87.5 | 0 |
| 로맨스 | 7 | 4.29 | 85.7 | 0 |
| 액션 | 18 | 4.06 | 83.3 | 0 |
| 코미디 | 4 | 4 | 75 | 0 |
| 판타지 | 3 | 3.67 | 66.7 | 0 |
| 공포 | 9 | 3 | 33.3 | 33.3 |

**읽는 법**
- 평균 대신 **호평률·혹평률**을 함께 본 이유: 평균 3.0 은 "모두 3점" 일 수도, "5점과 1점이 반반" 일 수도 있습니다. 공포 장르는 호평 33.3%, 혹평 33.3% 로 **호불호가 극명하게 갈리는** 장르입니다(파묘는 호평, 곤지암은 혹평).
- 액션은 리뷰 수가 가장 많지만(18) 호평률은 중간입니다. 많이 보지만 만족도는 평범한 장르 → 추천 정확도를 높일 여지가 있습니다.
- 드라마·SF·애니메이션은 리뷰가 9~11건으로 아직 표본이 작으니, 100% 라는 숫자보다 "혹평 0건" 이라는 점에 무게를 두는 것이 안전합니다.
- 뮤지컬은 영화가 없어 INNER JOIN 결과에서 빠졌습니다. 콘텐츠 공백을 찾는 용도라면 Q10 처럼 LEFT JOIN 으로 0 건 장르까지 보여줘야 합니다.
