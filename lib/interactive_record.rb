require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
    def self.table_name
        "#{self}".to_s.downcase.pluralize
    end

    def self.column_names
        DB[:conn].execute("PRAGMA table_info(#{table_name});").collect{|column| column[1]}
    end

    def initialize(attributes = {})
        attributes.each do |attr, value|
            self.class.attr_accessor(attr)
            self.send(("#{attr}="), value)
        end
    end

    def table_name_for_insert
        DB[:conn].execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")[0][0]
    end

    def col_names_for_insert
        self.class.column_names.delete_if{|item| item == "id"}.join(', ')
    end

    def values_for_insert
        values = []
        self.class.column_names.each do |col_name|
            values << "'#{send(col_name)}'" unless send(col_name).nil?
        end
        values.join(", ")
    end

    def save
        DB[:conn].execute("INSERT INTO #{self.class.table_name}(#{self.col_names_for_insert}) VALUES (#{self.values_for_insert});")
        self.id = DB[:conn].execute("SELECT last_insert_rowid()")[0][0]
    end

    def self.find_by_name(name)
        DB[:conn].execute("SELECT * FROM #{table_name} WHERE name = ?;", name)
    end

    def self.find_by(attribute)
        DB[:conn].execute("SELECT * FROM #{table_name} WHERE #{attribute.keys[0]} = ?;", attribute.values[0])
    end

end