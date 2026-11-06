"""Xuất đặc tả từng bảng Silver/Gold trong Training_Fresher_DeepChecked.xlsx ra docs/spec/<bang>.md.

Mục đích: đọc 1 file text nhỏ thay vì mở Excel mỗi lần. Chạy lại khi Excel đổi:
    pip install openpyxl && python scripts/export_spec.py
"""
from __future__ import annotations

from pathlib import Path

import openpyxl

ROOT = Path(__file__).resolve().parents[1]
XLSX = ROOT / "Training_Fresher_DeepChecked.xlsx"
OUT = ROOT / "docs" / "spec"
MAP_HEADER = ("Nguồn", "Bảng nguồn", "Cột nguồn")  # dòng tiêu đề bảng mapping


def cell(v) -> str:
    return "" if v is None else str(v).strip().replace("|", "\\|").replace("\n", "<br>")


def main() -> None:
    wb = openpyxl.load_workbook(XLSX, read_only=True, data_only=True)
    # Phan_Cong_Task: cột 5 = sheet, cột 6 = bảng đích, cột 7 = tầng
    tasks = [r for r in wb["Phan_Cong_Task"].iter_rows(values_only=True) if r and isinstance(r[0], int)]
    jobs = {
        str(r[1]).split(".")[-1].lower(): r
        for r in wb["Job_dependence"].iter_rows(values_only=True)
        if r and r[1] and "." in str(r[1])
    }
    OUT.mkdir(parents=True, exist_ok=True)
    index = ["| Bảng | Sheet | Tầng | Wave | Chờ |", "|---|---|---|---|---|"]
    for r in tasks:
        sheet, table, layer = str(r[4]), str(r[5]).lower(), r[6]
        if sheet not in wb.sheetnames or table.startswith("pg_bronze"):
            continue
        job = jobs.get(table)
        header, mapping, on = [], [], False
        for row in wb[sheet].iter_rows(values_only=True):
            if not any(row):
                continue
            if tuple(row[:3]) == MAP_HEADER:
                on = True
                continue
            vals = [cell(c) for c in row]
            if on:
                vals += [""] * 14
                # Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule
                mapping.append("| " + " | ".join(vals[i] for i in (1, 2, 3, 7, 8, 9, 10, 13)) + " |")
            else:
                header.append("- " + " · ".join(v for v in vals if v))
        lines = [
            f"# {table} — sheet '{sheet}'",
            "",
            f"Tầng: {layer}" + (f" · Wave: {job[2]} · Chờ: {job[3]}" if job else ""),
            "",
            "## Header (TYPE, bảng, JOIN, WHERE)",
            *header,
            "",
            "## Mapping",
            "| Bảng nguồn | Cột nguồn | Transform | Cột đích | Kiểu | Độ dài | Diễn giải | Business rule |",
            "|---|---|---|---|---|---|---|---|",
            *mapping,
        ]
        (OUT / f"{table}.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
        index.append(f"| [{table}]({table}.md) | {sheet} | {layer} | {job[2] if job else ''} | {cell(job[3]) if job else ''} |")
    (OUT / "README.md").write_text(
        "# Đặc tả từng bảng (sinh từ Excel bằng `scripts/export_spec.py`, đừng sửa tay)\n\n" + "\n".join(index) + "\n",
        encoding="utf-8",
    )
    print(f"{len(index) - 2} bảng -> {OUT}")


if __name__ == "__main__":
    main()
