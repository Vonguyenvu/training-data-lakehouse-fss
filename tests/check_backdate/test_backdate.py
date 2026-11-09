"""Kiểm tra Silver/Gold sau khi backdate (replay tăng dần tới ngày mới nhất).

Danh sách bảng đọc từ config của model dbt (silver_temp1, silver_temp2, gold):
- merge + unique_key có sys_eff_dt (SCD2): mỗi khóa tối đa 1 phiên bản mở, các phiên bản không chồng ngày.
- merge (SCD1 + SCD2), cần --etl-date = ngày replay cuối: không còn sys_* sau ngày đó.
- Cần --before = thời điểm trước khi backdate: merge so nguyên bảng 2 chiều (EXCEPT), insert_overwrite
  so số dòng từng partition. Chỉ đúng khi Bronze không đổi; backdate vì nguồn đã sửa thì khác biệt là có chủ đích.

docker compose exec airflow-scheduler bash -c "cd /opt/airflow && pytest -p no:cacheprovider tests/check_backdate \
    --etl-date 2026-11-08 --before '2026-11-10 08:00:00 Asia/Ho_Chi_Minh'"
"""
from __future__ import annotations

import ast
import re
from typing import NamedTuple

import pytest

from common.database.trino_connection import TrinoConnection
from tests.conftest import PROJECT_ROOT


class Model(NamedTuple):
    table: str  # iceberg.<schema>.<name>
    strategy: str
    keys: list[str]  # unique_key bỏ sys_eff_dt


def load_models() -> list[Model]:
    models = []
    for folder, schema in [("silver_temp1", "pg_silver"), ("silver_temp2", "pg_silver"), ("gold", "pg_gold")]:
        for path in sorted((PROJECT_ROOT / "dbt" / "models" / folder).glob("*.sql")):
            text = path.read_text(encoding="utf-8-sig")
            strategy = re.search(r"incremental_strategy\s*=\s*'(\w+)'", text).group(1)
            key = re.search(r"unique_key\s*=\s*(\[[^\]]*\]|'\w+')", text)
            keys = ast.literal_eval(key.group(1)) if key else []
            keys = [keys] if isinstance(keys, str) else keys
            models.append(Model(f"iceberg.{schema}.{path.stem}", strategy, keys))
    return models


MODELS = load_models()
MERGE = [m for m in MODELS if m.strategy == "merge"]
SCD2 = [m for m in MERGE if "sys_eff_dt" in m.keys]
OVERWRITE = [m for m in MODELS if m.strategy == "insert_overwrite"]


def by(models: list[Model]):
    return pytest.mark.parametrize("model", models, ids=lambda m: m.table.split(".", 1)[1])


def natural_key(model: Model) -> str:
    return ", ".join(k for k in model.keys if k != "sys_eff_dt")


@pytest.fixture(scope="session")
def before(request: pytest.FixtureRequest) -> str:
    value = request.config.getoption("--before")
    if value is None:
        pytest.skip("cần --before '<thời điểm trước backdate, kèm múi giờ>'")
    if not re.fullmatch(r"\d{4}-\d\d-\d\d \d\d:\d\d(:\d\d)? [\w/+:-]+", value):
        pytest.fail(f"--before sai định dạng: {value!r} (vd '2026-11-10 08:00:00 Asia/Ho_Chi_Minh')")
    return value


@pytest.fixture(scope="session")
def last_date(etl_date: str | None) -> str:
    if etl_date is None:
        pytest.skip("cần --etl-date <ngày replay cuối>")
    return etl_date


@by(SCD2)
def test_scd2_mot_phien_ban_mo(trino_conn: TrinoConnection, model: Model) -> None:
    key = natural_key(model)
    rows = trino_conn.query(
        f"SELECT {key}, count(*) FROM {model.table} WHERE sys_exp_dt IS NULL GROUP BY {key} HAVING count(*) > 1 LIMIT 5"
    )
    assert not rows, f"khóa có >1 phiên bản mở (5 mẫu): {rows}"


@by(SCD2)
def test_scd2_khong_chong_ngay(trino_conn: TrinoConnection, model: Model) -> None:
    key = natural_key(model)
    rows = trino_conn.query(
        f"""
        SELECT * FROM (
            SELECT {key}, sys_eff_dt, sys_exp_dt,
                   lead(sys_eff_dt) OVER (PARTITION BY {key} ORDER BY sys_eff_dt) AS next_eff
            FROM {model.table})
        WHERE next_eff IS NOT NULL AND (sys_exp_dt IS NULL OR sys_exp_dt > next_eff)
        LIMIT 5
        """
    )
    assert not rows, f"phiên bản chồng ngày (5 mẫu: khóa, eff, exp, eff kế tiếp): {rows}"


@by(MERGE)
def test_khong_co_ngay_tuong_lai(trino_conn: TrinoConnection, model: Model, last_date: str) -> None:
    ((n,),) = trino_conn.query(
        f"""
        SELECT count(*) FROM {model.table}
        WHERE sys_eff_dt > DATE '{last_date}' OR sys_exp_dt > DATE '{last_date}' OR sys_udt_dt > DATE '{last_date}'
        """
    )
    assert n == 0, f"{n} dòng có sys_* > {last_date}: chưa replay tới ngày này, hoặc còn sót dữ liệu sau ngày backdate"


@by(MERGE)
def test_giong_truoc_backdate(trino_conn: TrinoConnection, model: Model, before: str) -> None:
    old = f"{model.table} FOR TIMESTAMP AS OF TIMESTAMP '{before}'"
    ((missing,),) = trino_conn.query(f"SELECT count(*) FROM (SELECT * FROM {old} EXCEPT SELECT * FROM {model.table})")
    ((extra,),) = trino_conn.query(f"SELECT count(*) FROM (SELECT * FROM {model.table} EXCEPT SELECT * FROM {old})")
    assert (missing, extra) == (0, 0), f"khác trước backdate: mất {missing} dòng, thêm {extra} dòng"


@by(OVERWRITE)
def test_so_dong_partition_giong_truoc_backdate(trino_conn: TrinoConnection, model: Model, before: str) -> None:
    def counts(source: str) -> dict:
        return dict(trino_conn.query(f"SELECT CAST(etl_date AS VARCHAR), count(*) FROM {source} GROUP BY 1"))

    old = counts(f"{model.table} FOR TIMESTAMP AS OF TIMESTAMP '{before}'")
    new = counts(model.table)
    diff = {d: (old.get(d, 0), new.get(d, 0)) for d in old.keys() | new.keys() if old.get(d, 0) != new.get(d, 0)}
    assert not diff, f"số dòng partition khác (etl_date: trước, sau) — kiểm tra biz_date đã dùng: {diff}"
