# Lesson Exercises

-- # Exercise 1 — Model Design

from sqlalchemy import Column, Integer, ForeignKey, Text, DateTime, func, CheckConstraint
from sqlalchemy.orm import relationship
from base import Base

class Comment(Base):
    __tablename__ = "comments"

    id = Column(Integer, primary_key=True, autoincrement=True)
    task_id = Column(Integer, ForeignKey("tasks.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    content = Column(Text, nullable=False)
    created_at = Column(DateTime, server_default=func.now())

    __table_args__ = (
        CheckConstraint("content <> ''", name="ck_comments_content_not_empty"),
    )

    task = relationship("Task", back_populates="comments")
    user = relationship("User", back_populates="comments")


-- Add this inside the Task model:

-- comments = relationship(
--     "Comment",
--     back_populates="task",
--     cascade="all, delete-orphan"
-- )


-- Add this inside the User model:

-- comments = relationship(
--     "Comment",
--     back_populates="user"
-- )


-- 1. What relationships should Comment have?
-- Comment should have relationships with Task and User.
-- Each comment belongs to one task and one user.
-- A task can have many comments, and a user can write many comments.

-- 2. Should Task have a comments relationship?
-- Yes, Task should have a comments relationship.
-- This makes it easy to access all comments that belong to a task.

-- 3. What should happen to comments when a task is deleted?
-- The comments should also be deleted.
-- This prevents comments from staying in the database without a task.


-- # Exercise 2 — Migration Creation

from alembic import command
import glob

command.revision(
    alembic_cfg,
    autogenerate=True,
    message="add comments table"
)

migration_files = sorted(
    glob.glob('/content/project/alembic/versions/*.py')
)

for f in migration_files:
    print(f)

latest = migration_files[-1]

with open(latest) as f:
    print(f.read())


-- 1. What does upgrade() do?
-- upgrade() applies the new database changes.
-- In this case, it creates the comments table with its columns,
-- foreign keys, and constraints.

-- 2. What does downgrade() do?
-- downgrade() reverses the migration changes.
-- It removes what was created in upgrade().

-- 3. What happens if you downgrade this migration?
-- The comments table is dropped.
-- Any data stored inside the comments table is lost.


-- Bonus:
-- Add a CHECK constraint so content != ''

op.create_check_constraint(
    "ck_comments_content_not_empty",
    "comments",
    "content <> ''"
)

-- This constraint makes sure that a comment cannot be empty.


-- # Exercise 3 — CRUD Challenge

from sqlalchemy.orm import Session

session = Session(engine)

-- 1. Create a team called "DevOps"

devops_team = Team(
    name="DevOps",
    description="Team responsible for deployments and operations"
)

session.add(devops_team)
session.commit()

print("Team created:", devops_team.name)


-- 2. Create a user called "diana_ops"

diana = User(
    username="diana_ops",
    email="diana_ops@example.com",
    full_name="Diana Ops"
)

-- Use relationship

devops_team.users.append(diana)

session.add(diana)
session.commit()

print("User created:", diana.username)
print("User team:", diana.team.name)


-- 3. Create 3 tasks with different priorities


task_1 = Task(
    title="High priority task",
    description="Fix production issue",
    status="open"
)

task_2 = Task(
    title="Medium priority task",
    description="Update CI/CD pipeline",
    status="open"
)

task_3 = Task(
    title="Low priority task",
    description="Clean old server logs",
    status="open"
)

-- Use relationship

diana.tasks.append(task_1)
diana.tasks.append(task_2)
diana.tasks.append(task_3)

session.add_all([task_1, task_2, task_3])
session.commit()

print("Tasks created:")
for task in diana.tasks:
    print("-", task.title, "| Status:", task.status)


-- 4. Print task count

task_count = session.query(Task).count()
print("Total tasks:", task_count)


-- 5. Close one task

task_to_close = session.query(Task).filter_by(title="High priority task").first()
task_to_close.status = "closed"

session.commit()

print("Closed task:", task_to_close.title)


-- 6. Delete the lowest priority task

lowest_priority_task = session.query(Task).filter_by(title="Low priority task").first()

print("Deleting lowest priority task:", lowest_priority_task.title)

session.delete(lowest_priority_task)
session.commit()

print("Remaining tasks:")

remaining_tasks = session.query(Task).all()

for task in remaining_tasks:
    print("-", task.title, "| Status:", task.status)


-- # Exercise 4 — Migration Rollback

command.downgrade(alembic_cfg, "-1")


-- 1. What happens to the column?
-- The estimated_hours column is removed from the database.
-- The database goes back to the previous migration version.

-- 2. What happens to the data?
-- The data stored in the estimated_hours column is deleted.
-- Once the column is removed, the values are lost.


-- # Exercise 5 — Concept Check

-- 1. Why use ORM instead of raw SQL?
-- ORM lets us work with Python objects instead of writing raw SQL.
-- It makes the code easier to read and maintain.

-- 2. Why use migrations?
-- Migrations help track database schema changes over time.
-- They make it possible to upgrade or downgrade the database safely.

-- 3. When would you rollback?
-- We rollback when a migration has a mistake,
-- breaks something, or adds a bad change.

-- 4. Difference between add() and commit()?
-- add() puts the object into the session.
-- commit() saves the changes permanently in the database.

-- 5. Why are relationships useful?
-- Relationships connect tables in the ORM.
-- They make it easier to access related data without writing complex SQL.