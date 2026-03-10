
### `sql_challenges/challenge-05/README.md`

```md
# SQL Challenge 01 – Index Usage

## Problem
Union, Minus, and Intersect: Databases for Developers
An introduction to the set operators, union, minus, and intersect

## Schema
```sql
CREATE TABLE orders (
  id BIGINT PRIMARY KEY,
  customer_id BIGINT,
  created_at TIMESTAMP,
  status TEXT
);

── sql_challenges/
│   ├── challenge-01/
│   │   ├── README.md
│   │   ├── solution.sql
│   │   └── notes.md
│   ├── challenge-02/
│   │   └── README.md