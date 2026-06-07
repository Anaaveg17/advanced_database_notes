# Notes 
- ORM = work with Python objects instead of raw SQL
- Tables become classes
- Rows become objects
- Easier to read and maintain than large SQL queries

Relationships

One Team: many Users
One User: many Tasks
One Task: many Comments

use:
- easier navigation between tables
- avoids manual JOIN queries
- cleaner code


- SQLAlchemy makes DB work feel more Pythonic
- Relationships simplify querying
- Alembic keeps schema history organized
- Rollbacks are useful but can delete data
- Constraints help keep database clean
