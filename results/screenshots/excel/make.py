"""엑셀 한 시트 방식의 문제를 실제 스프레드시트로 재현하는 파일 생성기 (results/screenshots/EXCEL.png).

    docker build -t calc-demo results/screenshots/excel          # LibreOffice Calc 24.2 + openpyxl
    docker run --rm -v "$PWD/results/screenshots/excel:/w" -w /w calc-demo bash -c \
      'python3 make.py && for f in before after; do soffice --headless --convert-to csv $f.xlsx; soffice --headless --convert-to pdf $f.xlsx; done'

before.xlsx: 회원 3명 + 리뷰 4건(닉네임은 VLOOKUP). after.xlsx: 회원 시트에서 2번 행을 delete_rows 로 지운 상태.
LibreOffice 가 열면서 다시 계산한 결과가 before.csv / after.csv (리뷰 2 · 4 의 닉네임이 #N/A).
이 스크립트는 프로젝트 의존성이 아니다(openpyxl · LibreOffice 는 위 컨테이너 안에서만 쓴다).
"""
# 엑셀(xlsx) 두 개: before = 회원 3명, after = 회원 시트에서 2번 회원 행을 실제로 delete_rows 로 지운 상태
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill
def book():
    wb = Workbook()
    rv = wb.active; rv.title = "리뷰"
    mb = wb.create_sheet("회원")
    mb.append(["member_id", "nickname"])
    for r in [(1, "팝콘요정"), (2, "시네필"), (3, "스릴러킹")]: mb.append(list(r))
    rv.append(["review_id", "member_id", "별점", "닉네임 (VLOOKUP → 회원 시트)"])
    data = [(1, 1, 5), (2, 2, 4), (3, 3, "다섯"), (4, 2, 6)]
    for i, (a, b, c) in enumerate(data, start=2):
        rv.append([a, b, c, "=VLOOKUP(B{0},회원!$A$2:$B$4,2,FALSE)".format(i)])
    for c in rv[1]: c.font = Font(bold=True); c.fill = PatternFill("solid", fgColor="DDDDDD")
    for c in mb[1]: c.font = Font(bold=True); c.fill = PatternFill("solid", fgColor="DDDDDD")
    rv.column_dimensions["D"].width = 30; rv.column_dimensions["A"].width = 11; rv.column_dimensions["B"].width = 11
    for ws in (rv, mb):
        ws.print_options.gridLines = True
        ws.print_options.headings = True          # 열 문자 · 행 번호를 함께 인쇄 (화면처럼)
        ws.page_setup.orientation = "landscape"
        ws.sheet_properties.pageSetUpPr.fitToPage = True
        ws.page_setup.fitToWidth = 1; ws.page_setup.fitToHeight = 0
    rv["F2"] = "D2 수식:"; rv["G2"] = "=_xlfn.FORMULATEXT(D2)"
    rv.column_dimensions["G"].width = 44
    return wb
wb = book(); wb.save("before.xlsx")
wb = book(); wb["회원"].delete_rows(3); wb.save("after.xlsx")   # 회원 2(시네필) 행 삭제 — 경고 없이 지워진다
