-- Tỷ giá mid phải dương; test fail nếu câu truy vấn trả về dòng nào.
SELECT *
FROM {{ ref('exg_rate') }}
WHERE mid_rate <= 0
