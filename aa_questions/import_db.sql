DROP TABLE users;
DROP TABLE questions;
DROP TABLE question_follows;
DROP TABLE replies;
DROP TABLE question_likes;


CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname VARCHAR(255) NOT NULL,
  lname VARCHAR(255) NOT NULL
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT,
  author INTEGER NOT NULL,
  FOREIGN KEY(author) REFERENCES users(id)
);

CREATE TABLE question_follows (
  id INTEGER PRIMARY KEY,
  questions_id INTEGER NOT NULL,
  users_id INTEGER NOT NULL,
  FOREIGN KEY(questions_id) REFERENCES questions(id),
  FOREIGN KEY(users_id) REFERENCES users(id)
);

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  parent INTEGER,
  author INTEGER NOT NULL,
  body TEXT NOT NULL,
  subject INTEGER NOT NULL,
  FOREIGN KEY(author) REFERENCES users(id),
  FOREIGN KEY(parent) REFERENCES replies(id),
  FOREIGN KEY(subject) REFERENCES questions(id)
);

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,
  FOREIGN KEY(user_id) REFERENCES users(id),
  FOREIGN KEY(question_id) REFERENCES questions(id)
);

INSERT INTO users (fname, lname) VALUES
  ('Jon', 'Doe'),
  ('Jane', 'Doe'),
  ('Adam', 'Smith');
INSERT INTO questions (title, body, author) VALUES
  ('What are birds?', 'What are they, really?', 1),
  ('How do you type?', 'I don''t know how to work a keyboard', 2),
  ('What is the meaning of life?', NULL, 3);
INSERT INTO replies (parent, author, body, subject) VALUES
  (Null, 2, "Hi123", 1),
  (1, 3, "Subtext", 1),
  (1, 1, "hehe", 1);
