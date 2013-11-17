class ReplaceOffsetsWithReferencesAst

  attr_accessor :replacements_made_in_the_last_pass

  def initialize
    @replacements_made_in_the_last_pass = 0
  end
    
  def map(ast)
    return ast unless ast.is_a?(Array)
    operator = ast[0]
    if respond_to?(operator)
      send(operator,*ast[1..-1])
    else
      [operator,*ast[1..-1].map {|a| map(a) }]
    end
  end
  
  def function(name,*args)
    if name == "OFFSET" && args.size == 5 && args[0][0] == :cell && args[1][0] == :number && args[2][0] == :number && args[3][0] == :number && args[4][0] == :number 
      replace_offset(args[0][1], args[1][1], args[2][1], args[3][1], args[4][1])
    elsif name == "OFFSET" && args.size == 3 && args[0][0] == :cell && args[1][0] == :number && args[2][0] == :number
      replace_offset(args[0][1], args[1][1], args[2][1])
    else
      puts "offset in #{[:function,name,*args.map { |a| map(a) }].inspect} not replaced" if name == "INDIRECT"
      [:function,name,*args.map { |a| map(a) }]
    end
  end

  def replace_offset(reference, row_offset, column_offset, height = 1, width = 1)
    @replacements_made_in_the_last_pass += 1
    reference = Reference.for(reference.gsub("$",""))
    start_reference = reference.offset(row_offset.to_i, column_offset.to_i)
    end_reference = reference.offset(row_offset.to_i + height.to_i - 1, column_offset.to_i + width.to_i - 1)
    if start_reference == end_reference
      [:cell, start_reference]
    else
      [:area, start_reference, end_reference]
    end
  end

end
  

class ReplaceOffsetsWithReferences
    
  def self.replace(*args)
    self.new.replace(*args)
  end
  
  attr_accessor :replacements_made_in_the_last_pass
  
  def replace(input,output)
    rewriter = ReplaceOffsetsWithReferencesAst.new
    input.each_line do |line|
      # Looks to match lines with references
      if line =~ /"OFFSET"/
        ref, ast = line.split("\t")
        output.puts "#{ref}\t#{rewriter.map(eval(ast)).inspect}"
      else
        output.puts line
      end
    end
    @replacements_made_in_the_last_pass = rewriter.replacements_made_in_the_last_pass
  end
end
