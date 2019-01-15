require_relative '../spec_helper'

describe ReplaceColumnAndRowFunctions do
  
it "should replace COLUMN() and ROW() functions with the number of the column or row that they refer to" do

input = <<END
A1\t[:function, :COLUMN, [:cell, :"$A$5"]]
A2\t[:function, :COLUMN, [:area, :"$A$5", "$C$5"]]
A3\t[:function, :COLUMN, [:sheet_reference, "Sheet1", [:cell, :G70]]]
A4\t[:function, :ROW, [:cell, :"$A$5"]]
A5\t[:function, :ROW, [:sheet_reference, "Sheet1", [:area, :G70, :H50]]]
A6\t[:function, :ROW]
A7\t[:function, :COLUMN]
A8\t[:arithmetic, [:function, :INDEX, [:area, "$F$222", "$O$230"], [:function, "MATCH", [:cell, "$D498"], [:area, "$E$222", "$E$230"], [:number, "0"]], [:arithmetic, [:function, :COLUMN], [:operator, "-"], [:function, :COLUMN, [:cell, "$F$403"]], [:operator, "+"], [:number, "1"]]], [:operator, "*"], [:cell, "L340"]]
A9\t[:function, :COLUMN, [:array, [:row, [:sheet_reference, :Sheet1, [:cell, :A2]], [:sheet_reference, :Sheet1, [:cell, :B2]]]]]
A10\t[:function, :COLUMN, [:array, [:row, [:cell, :A2], [:cell, :B2]]]]
A11\t[:function, :COLUMN, [:array, [:row, [:area, :A2, :B2], [:cell, :B2]]]]
END

expected_output = <<END
A1\t[:number, 1.0]
A2\t[:number, 1.0]
A3\t[:number, 7.0]
A4\t[:number, 5.0]
A5\t[:number, 70.0]
A6\t[:number, 6.0]
A7\t[:number, 1.0]
A8\t[:arithmetic, [:function, :INDEX, [:area, "$F$222", "$O$230"], [:function, "MATCH", [:cell, "$D498"], [:area, "$E$222", "$E$230"], [:number, "0"]], [:arithmetic, [:number, 1.0], [:operator, "-"], [:number, 6.0], [:operator, "+"], [:number, "1"]]], [:operator, "*"], [:cell, "L340"]]
A9\t[:number, 1.0]
A10\t[:number, 1.0]
A11\t[:number, 1.0]
END
    
input = StringIO.new(input)
output = StringIO.new
r = ReplaceColumnAndRowFunctions.new
r.replace(input,output)
output.string.should == expected_output

end # / it


end # / describe
