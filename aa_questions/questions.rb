require 'sqlite3'
require 'singleton'
require 'byebug'
require 'active_support'


class QuestionsDBConnection < SQLite3::Database
  include Singleton

  def initialize
    super("questions.db")
    self.type_translation = true
    self.results_as_hash = true
  end
end




#-----------------------------------------------------------------------




include ActiveSupport::Inflector
class ModelBase

  def self.find_by_id(id)
    data = QuestionsDBConnection.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      #{tableize(self.to_s)}
    WHERE
      id = ?
    SQL
    self.new(data.first)
  end

  def self.all
    data = QuestionsDBConnection.instance.execute(<<-SQL)
    SELECT
      *
    FROM
      #{tableize(self.to_s)}
    SQL
    data.map { |datum| self.new(datum) }
  end

  def save
    if self.id
      update
    else
      insert
      self.id = QuestionsDBConnection.instance.last_insert_row_id
    end
  end

  private

  def get_table_name
    tableize(self.class.to_s)
  end

  def fields
    self.instance_variables.map { |v| v.to_s[1..-1] }.reject { |s| s == 'id'}
  end

  def fields_values
    self.instance_variables.reject { |v| v == :@id }.map { |var| self.send(var[1..-1].to_sym) }
  end

  def value_questions
    (['?'] * fields.length).join(", ")
  end

  def fields_string
    fields.join(", ")
  end

  def field_set_string
    fields.map! do |field|
      field.concat(" = ?")
    end.join(", ")
  end

  def insert
    QuestionsDBConnection.instance.execute(<<-SQL, fields_values)
    INSERT INTO #{get_table_name} (#{fields_string})
    VALUES
      (#{value_questions})
    SQL
  end

  def update
    QuestionsDBConnection.instance.execute(<<-SQL, fields_values, self.id)
    UPDATE #{get_table_name}
    SET #{field_set_string}
    WHERE id = ?
    SQL
  end
end





#-----------------------------------------------------------------------





class User < ModelBase
  attr_accessor :fname, :lname, :id


  def self.find_by_name(fname, lname)
    data = QuestionsDBConnection.instance.execute(<<-SQL, fname, lname)
    SELECT
      *
    FROM
      users
    WHERE
      fname = ?
      AND
      lname = ?
    SQL
    data.map { |datum| self.new(datum) }
  end

  def initialize(options)
    @fname = options['fname']
    @lname = options['lname']
    @id = options['id']
  end

  def authored_questions
    Question.find_by_author_id(self.id)
  end

  def authored_replies
    Reply.find_by_user_id(self.id)
  end

  def followed_questions
    QuestionFollow.followed_questions_for_user_id(self.id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(self.id)
  end

  def average_karma
    data = QuestionsDBConnection.instance.execute(<<-SQL, self.id)
    SELECT
    ((COUNT(*) + 0.0) / COUNT(DISTINCT questions.id)) as avg_karma
    FROM
    users
    JOIN questions
      ON questions.author_id = users.id
    JOIN question_likes
      ON question_likes.question_id = questions.id
    WHERE users.id = ?
    SQL
    data.first['avg_karma']
  end

end



#-----------------------------------------------------------------------



class Question < ModelBase
  attr_accessor :title, :body, :author_id
  attr_reader :id

  def self.find_by_id(id)
    data = QuestionsDBConnection.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      questions
    WHERE
      id = ?
    SQL
    self.new(data.first)
  end

  def self.find_by_author_id(author_id)
    data = QuestionsDBConnection.instance.execute(<<-SQL, author_id)
    SELECT
      *
    FROM
      questions
    WHERE
      author_id = ?
    SQL
    data.map { |datum| self.new(datum) }
  end

  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end

  def author
    User.find_by_id(self.author_id)
  end

  def replies
    Reply.find_by_question_id(self.id)
  end

  def followers
    QuestionFollow.followers_for_question_id(self.id)
  end

  def likers
    QuestionLike.likers_for_question_id(self.id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(self.id)
  end
end




#-----------------------------------------------------------------------






class Reply < ModelBase
  attr_accessor :parent_id, :body, :author_id, :subject_id
  attr_reader :id

  def self.find_by_id(id)
    data = QuestionsDBConnection.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      replies
    WHERE
      id = ?
    SQL
    self.new(data.first)
  end

  def self.find_by_user_id(user_id)
    data = QuestionsDBConnection.instance.execute(<<-SQL, user_id)
    SELECT
      *
    FROM
      replies
    WHERE
      author_id = ?
    SQL
    data.map { |datum| self.new(datum) }
  end

  def self.find_by_question_id(question_id)
    data = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
    SELECT
      *
    FROM
      replies
    WHERE
       subject_id = ?
    SQL
    data.map { |datum| self.new(datum) }
  end

  def self.find_by_parent_id(parent_id)
    data = QuestionsDBConnection.instance.execute(<<-SQL, parent_id)
    SELECT
      *
    FROM
      replies
    WHERE
       parent_id = ?
    SQL
    data.map { |datum| self.new(datum) }
  end

  def initialize(options)
    @id = options['id']
    @parent_id = options['parent_id']
    @body = options['body']
    @author_id = options['author_id']
    @subject_id = options['subject_id']
  end

  def author
    User.find_by_id(self.author_id)
  end

  def question
    Question.find_by_id(self.subject_id)
  end

  def parent_reply
    Reply.find_by_id(self.parent_id)
  end

  def child_replies
    Reply.find_by_parent_id(self.id)
  end

end




#-----------------------------------------------------------------------





class QuestionFollow < ModelBase
  attr_accessor :question_id, :user_id
  attr_reader :id

  def self.find_by_id(id)
    data = QuestionsDBConnection.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      question_follows
    WHERE
      id = ?
    SQL
    self.new(data.first)
  end

  def self.followers_for_question_id(question_id)
    data = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
    SELECT
      users.*
    FROM
      question_follows
      JOIN users
        ON user_id = users.id
    WHERE
       question_follows.question_id = ?
    SQL
    data.map { |datum| User.new(datum) }
  end

  def self.followed_questions_for_user_id(user_id)
    data = QuestionsDBConnection.instance.execute(<<-SQL, user_id)
    SELECT
      questions.*
    FROM
      question_follows
      JOIN questions
        ON question_id = questions.id
    WHERE
       question_follows.user_id = ?
    SQL
    data.map { |datum| Question.new(datum) }
  end

  def self.most_followed_questions(n)
    data = QuestionsDBConnection.instance.execute(<<-SQL, n)
    SELECT
      questions.*
    FROM
      question_follows
      JOIN questions
        ON question_follows.question_id = questions.id
    GROUP BY questions.id
    ORDER BY COUNT(question_id) DESC
    LIMIT ?
    SQL
    data.map { |datum| Question.new(datum) }
  end

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
  end
end




#-----------------------------------------------------------------------





class QuestionLike < ModelBase
  attr_accessor :question_id, :user_id
  attr_reader :id

  def self.find_by_id(id)
    data = QuestionsDBConnection.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      question_likes
    WHERE
      id = ?
    SQL
    self.new(data.first)
  end

  def self.likers_for_question_id(question_id)
    data = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
    SELECT
      users.*
    FROM
      question_likes
      JOIN users
        ON question_likes.user_id = users.id
    WHERE
       question_likes.question_id = ?
    SQL
    data.map { |datum| User.new(datum) }
  end

  def self.num_likes_for_question_id(question_id)
    data = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
    SELECT
      COUNT(users.id) as count
    FROM
      question_likes
      JOIN users
        ON question_likes.user_id = users.id
    WHERE
       question_likes.question_id = ?
    SQL
    data.first["count"]
  end

  def self.liked_questions_for_user_id(user_id)
    data = QuestionsDBConnection.instance.execute(<<-SQL, user_id)
    SELECT
      questions.*
    FROM
      question_likes
      JOIN questions
        ON question_likes.question_id = questions.id
    WHERE
       question_likes.user_id = ?
    SQL
    data.map { |datum| Question.new(datum) }
  end

  def self.most_liked_questions(n)
    data = QuestionsDBConnection.instance.execute(<<-SQL, n)
    SELECT
      questions.*
    FROM
      question_likes
      JOIN questions
        ON question_likes.question_id = questions.id
    GROUP BY questions.id
    ORDER BY COUNT(question_id) DESC
    LIMIT ?
    SQL
    data.map { |datum| Question.new(datum) }
  end

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
  end
end
