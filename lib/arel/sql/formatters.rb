module Arel
  module Sql
    class Formatter
      attr_reader :environment
      delegate :christener, :engine, :to => :environment
      delegate :name_for, :to => :christener
      delegate :quote_table_name, :quote_column_name, :quote, :to => :engine

      def initialize(environment)
        @environment = environment
      end
    end

    class SelectClause < Formatter
      def attribute(attribute)
        # FIXME this should check that the column exists
        if attribute.name.to_s =~ /^\w*$/
          "#{quote_table_name(name_for(attribute.original_relation))}.#{quote_column_name(attribute.name)}" + (attribute.alias ? " AS #{quote(attribute.alias.to_s)}" : "")
        else
          attribute.name.to_s + (attribute.alias ? " AS #{quote(attribute.alias.to_s)}" : "")
        end
      end

      def expression(expression)
        if expression.function_sql == "DISTINCT"
          "#{expression.function_sql} #{expression.attribute.to_sql(self)}" + (expression.alias ? " AS #{quote_column_name(expression.alias)}" : '')
        else
          "#{expression.function_sql}(#{expression.attribute.to_sql(self)})" + (expression.alias ? " AS #{quote_column_name(expression.alias)}" : '')
        end
      end

      def select(select_sql, table)
        "(#{select_sql}) AS #{quote_table_name(name_for(table))}"
      end

      def value(value)
        value
      end
    end

    class PassThrough < Formatter
      def value(value)
        value
      end
    end

    class WhereClause < PassThrough
    end

    class OrderClause < PassThrough
      def attribute(attribute)
        "#{quote_table_name(name_for(attribute.original_relation))}.#{quote_column_name(attribute.name)}"
      end
    end

    class GroupClause < PassThrough
      def attribute(attribute)
        "#{quote_table_name(name_for(attribute.original_relation))}.#{quote_column_name(attribute.name)}"
      end
    end

    class WhereCondition < Formatter
      def attribute(attribute)
        "#{quote_table_name(name_for(attribute.original_relation))}.#{quote_column_name(attribute.name)}"
      end

      def expression(expression)
        "#{expression.function_sql}(#{expression.attribute.to_sql(self)})"
      end

      def value(value)
        value.to_sql(self)
      end

      def scalar(value, column = nil)
        quote(value, column)
      end

      def select(select_sql, table)
        "(#{select_sql})"
      end
    end

    class SelectStatement < Formatter
      def select(select_sql, table)
        select_sql
      end
    end

    class TableReference < Formatter
      def select(select_sql, table)
        "(#{select_sql}) AS #{quote_table_name(name_for(table))}"
      end

      def table(table)
        if table.name =~ /^(\w|-)*$/
          quote_table_name(table.name) + (table.name != name_for(table) ? " AS " + quote_table_name(name_for(table)) : '')
        else
          table.name + (table.name != name_for(table) ? " AS " + (name_for(table)) : '')
        end
      end
    end

    class Attribute < WhereCondition
      def scalar(scalar)
        quote(scalar, environment.column)
      end

      def array(array)
        "(" + array.collect { |e| e.to_sql(self) }.join(', ') + ")"
      end

      def range(left, right)
        "#{left} AND #{right}"
      end
    end

    class Value < WhereCondition
    end
  end
end
