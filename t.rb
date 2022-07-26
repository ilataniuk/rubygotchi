#!/usr/bin/ruby

require 'json'

module VariableHelpers

    def var_non_int?(var)
        var == :@name || var == :@face
    end

    def normalize_vars
        # animal's variables must be in range [0..100]%
        for var in self.instance_variables
            next if var_non_int?(var)
            v = instance_variable_get(var);
            instance_variable_set(var,0) if v<0
            instance_variable_set(var,100) if v>100
        end
        to_s
    end

    def to_s
        self.instance_variables.map { |var|
            var.to_s + ':' +
            instance_variable_get(var).to_s +
            (var_non_int?(var) ? '' : '%')
        }.join(' ')
    end
end

class Animal

    attr_accessor :name, :face

    include VariableHelpers

    def initialize(params={})
        @name = params.has_key?(:@name) ? params[:@name].to_s : ''
        @face = params.has_key?(:@face) ? params[:@face].to_s : '(_^-^)'
        @fullness = params.has_key?(:@fullness) ? params[:@fullness].to_i : 10
        @happiness = params.has_key?(:@happiness) ? params[:@happiness].to_i : 50
        @liveliness = params.has_key?(:@liveliness) ? params[:@liveliness].to_i : 0
    end

    def eat
        if hungry?
            @fullness = 100
            @happiness += 50
            @liveliness -= 10
            normalize_vars
        else
            "I'm not hangry!"
        end
    end

    def run
        if tired?
            "No, I'm tired!"
        else
            @fullness -= 40
            @happiness += 50
            @liveliness -= 50
            normalize_vars
        end
    end

    def sleep
        if happy?
            @fullness -= 20
            @happiness -= 50
            @liveliness = 100
            normalize_vars
        else
            "I can't sleep so unhappy"
        end
    end

    private

    def hungry?
       @fullness < 80
    end

    def happy?
       @happiness > 60
    end

    def tired?
       @liveliness < 30
    end
end

class ConsoleIO

    def initialize
        @animal = nil
        @st_path = File::dirname(__FILE__)+'/'+File::basename(__FILE__,File::extname(__FILE__))+'.st';

        puts "Warning(!) after quit from app your animal will die" if File.exist?(@st_path) && !File.writable?(@st_path)

        # restore saved aminal
        hash = load_state
        @animal = Animal.new(hash) unless hash.empty?

        # when pressed ctrl+c
        trap "SIGINT" do
            puts "\n"
            save_state
            exit 130
        end
    end

    def save_state
        puts @animal.face + " Buy! Don't forget about me..." unless @animal.nil?
        File.open(@st_path, "w") do |file|
            file.write(@animal.instance_variables.map { |k| [k,@animal.instance_variable_get(k)] }.to_h.to_json)
        end
        rescue
    end

    def load_state
        data = {}
        begin
            File.open(@st_path, "r") do |file|
                data = JSON.parse(file.read,{symbolize_names: true})
            end
        rescue
        end
        return data
    end

    def run
        cmd = answer = ''
        available_cmd = Animal.instance_methods(false).grep(/^([a-z]+)$/).join(',')
        while cmd != 'quit'

            print "\nEnter command [new,#{available_cmd},kill,quit]: "
            cmd = gets.chomp()

            if (@animal.nil? && (cmd != 'new'))
                answer = "You should use command 'new' to create"
            else
                case cmd
                when 'new'
                    answer = @animal.nil? ? "You have got the animal!" : "Hey, I'm alive!"
                    @animal = Animal.new if @animal.nil?
                when 'name'
                    if @animal.name.length == 0
                        print "Enter name: "
                        @animal.name = gets.chomp()
                        answer = "As you wish!"
                    else
                        answer = "Hey, my name is " + @animal.name
                    end
                when 'kill'
                    answer = "#{@animal.face} Hasta la vista, baby!"
                    @animal = nil
                else
                    answer = @animal.respond_to?(cmd) ? @animal.send(cmd) : "Unsupported command"
                end
                answer = @animal.face + ' ' + answer unless @animal.nil?
            end
            puts answer unless cmd == 'quit'
        end
        save_state
    end

end

ConsoleIO.new.run
