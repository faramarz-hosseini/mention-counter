# frozen_string_literal: true

require 'sqlite3'

# interface to interact with local sqlite file
# the interface is very naive and by no means complete
# its mere purpose was to serve as a tutorial and get me started
# in the Ruby language
class SqliteCli
  attr_accessor :storage

  def initialize(db_name)
    @storage = SQLite3::Database.new db_name, { results_as_hash: true }
    @sql_condition_handlers = {
      eq: method(:sql_equal),
      gt: method(:sql_gt)
    }
  end

  def read(table_name, fields, conditions) # rubocop:disable Metrics/MethodLength
    statement = <<-SQL
      SELECT #{fields.join(',')} FROM #{table_name}
    SQL
    unless conditions.nil?
      where_clause = 'WHERE '
      conditions.each do |cond|
        signature, field, value = extract_condition_signature_params(cond)
        condition_sql = @sql_condition_handlers[signature].call(field, value)
        where_clause += "#{condition_sql} AND "
      end
      where_clause = where_clause[0..-5] if where_clause.end_with?('AND ')
      statement += "#{where_clause};"
    end
    @storage.execute statement
  end

  def write(table_name, fields, values)
    converted_values = []
    values.each do |val|
      if val.is_a? Numeric
        converted_values.push(val)
      else
        converted_values.push("'#{val}'")
      end
    end

    @storage.execute <<-SQL
      INSERT INTO #{table_name} (#{fields.join(',')}) VALUES (#{converted_values.join(',')});
    SQL
  end

  def update(table_name, fields, values, conditions) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    raise 'length of fields and values for update must be equal' if fields.length != values.length
    raise 'update query without condition is not allowed' if conditions.empty? || conditions.nil?

    update_statement = "UPDATE #{table_name} SET "
    fields.zip(values).each do |field_val_couple|
      field = field_val_couple[0]
      val = field_val_couple[1]
      val = "'#{val}'" unless val.is_a? Numeric
      update_statement += "#{field} = #{val},"
    end
    update_statement = update_statement[0..-2] if update_statement.end_with?(',')

    where_clause = ' WHERE '
    conditions.each do |cond|
      signature, field, value = extract_condition_signature_params(cond)
      condition_sql = @sql_condition_handlers[signature].call(field, value)
      where_clause += "#{condition_sql} AND "
    end
    where_clause = where_clause[0..-5] if where_clause.end_with?('AND ')
    update_statement += "#{where_clause};"

    @storage.execute update_statement
  end

  private

  def extract_condition_signature_params(condition_container)
    signature = condition_container[:signature]
    params = condition_container[:params]
    raise 'signature was not passed' if signature.nil?
    raise 'bad condition params' if !params.is_a?(Array) && (params.length != 2)

    [signature, params[0], params[1]]
  end

  def sql_equal(col, val)
    "#{col} = '#{val}'"
  end

  def sql_gt(col, val)
    converted_val = if val.is_a? Numeric
                      val
                    else
                      "'#{val}'"
                    end

    "#{col} > #{converted_val}"
  end
end
