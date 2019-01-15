require_relative '../spec_helper'

describe ReplaceArraysWithSingleCellsAst do
  
  it "should replace array literals (e.g., {A1,B1;A2,B2}) with the appropriate cell (e.g., A1) where it is required" do

  r = ReplaceArraysWithSingleCellsAst.new

  ast = [:array, [:row, [:sheet_reference, :"sheet1", [:cell, :"B1"]], [:sheet_reference, :"sheet1", [:cell, :"C1"]]]]

  r.ref = [:sheet1, :B10]
  r.map(ast).should == [:sheet_reference, :"sheet1", [:cell, :"B1"]] 

  r.ref = [:sheet1, :C10]
  r.map(ast).should == [:sheet_reference, :"sheet1", [:cell, :"C1"]] 

  r.ref = [:sheet1, :D10]
  r.map(ast).should ==   [:error, :"#VALUE!"]  # [:array, [:row, [:sheet_reference, :sheet1, [:cell, :B1]], [:sheet_reference, :sheet1, [:cell, :C1]]]] # Excel would return a #VALUE! but we need to return the array in case it is part of function that accepts an array FIXME: Do this properly someitme

  r.ref = [:sheet1, :B10]
  r.map([:function, :SUM, *ast]).should == [:function, :SUM, *ast]

  ast_vertical =  [:array, [:row, [:sheet_reference, :"sheet1", [:cell, :"A2"]]], [:row, [:sheet_reference, :"sheet1", [:cell, :"A3"]]]]

  r.ref = [:sheet1, :Z2]
  r.map(ast_vertical).should == [:sheet_reference, :sheet1, [:cell, :A2]]
  
  r.ref = [:sheet1, :Z12]
  r.map(ast_vertical).should == [:error, :"#VALUE!"] 

  r.ref = [:sheet1, :Z2]
  r.map([:function, :SUM, *ast_vertical]).should == [:function, :SUM, *ast_vertical]

  r.ref = [:sheet1, :B2]
  r.map([:arithmetic, ast, [:operator, :+], ast_vertical]).should == [:arithmetic, [:sheet_reference, :"sheet1", [:cell, :"B1"]], [:operator, :+], [:sheet_reference, :sheet1, [:cell, :A2]]]

  r.map([:string_join, ast, ast_vertical]).should == [:string_join, [:sheet_reference, :"sheet1", [:cell, :"B1"]], [:sheet_reference, :sheet1, [:cell, :A2]]]

  r.map([:function, :INDIRECT, [:string_join, ast, ast_vertical]]).should == [:function, :INDIRECT, [:string_join, [:sheet_reference, :"sheet1", [:cell, :"B1"]], [:sheet_reference, :sheet1, [:cell, :A2]]]]

  r.map([:function, :OFFSET,  ast_vertical, ast_vertical, ast_vertical, ast_vertical, ast_vertical]).should == [:function, :OFFSET, ast_vertical, [:sheet_reference, :sheet1, [:cell, :A2]], [:sheet_reference, :sheet1, [:cell, :A2]], [:sheet_reference, :sheet1, [:cell, :A2]], [:sheet_reference, :sheet1, [:cell, :A2]]]

  sumifast = [:function, :SUMIF, ast_vertical, ast_vertical ] 
  sumifast_result = [:function, :SUMIF, ast_vertical, [:sheet_reference, :sheet1, [:cell, :A3]]]
  r.ref = [:sheet1, :B3]
  r.map(sumifast).should == sumifast_result

  sumifsast = [:function, :SUMIFS, ast_vertical, ast_vertical, ast_vertical ] 
  sumifsast_result = [:function, :SUMIFS, ast_vertical, ast_vertical, [:sheet_reference, :sheet1, [:cell, :A3]]]
  r.ref = [:sheet1, :B3]
  r.map(sumifsast).should == sumifsast_result


  ast_vertical =  [:array, [:row, [:sheet_reference, :"sheet1", [:cell, :"A2"]]], [:row, [:sheet_reference, :"sheet1", [:cell, :"A3"]]]]
  if_ast = [:function, :IF, [:boolean_true], ast_vertical, ast_vertical]
  r.ref = [:sheet1, :B3]
  r.map(if_ast).should == [:function, :IF, [:boolean_true], [:sheet_reference, :sheet1, [:cell, :A3]], [:sheet_reference, :sheet1, [:cell, :A3]]]

  index_ast = [:function, :INDEX, ast_vertical, ast_vertical, ast_vertical]
  r.ref = [:sheet1, :B3]
  r.map(index_ast).should == [:function, :INDEX, ast_vertical, [:sheet_reference, :sheet1, [:cell, :A3]], [:sheet_reference, :sheet1, [:cell, :A3]]]

  end

  it "should work even if the array contents has been replaced with literals" do
    r = ReplaceArraysWithSingleCellsAst.new
    c1 = [:sheet_reference, :"sheet1", [:cell, :"B1"]]
    c2 = [:sheet_reference, :"sheet1", [:cell, :"C1"]]
    ast = [:array, [:row, c1, c2 ]]
    r.ref = [:sheet1, :C10]
    r.map(ast).should == [:sheet_reference, :"sheet1", [:cell, :"C1"]] 
    c1.replace([:inlined_blank])
    c2.replace([:number, 12.0])
    r.map(ast).should == [:number, 12.0]
  end

  it "should work with arrays inside prefixes" do
    r = ReplaceArraysWithSingleCellsAst.new
    r.ref = [:sheet1, :B2]

    array = [:array, [:row, [:sheet_reference, :"sheet1", [:cell, :"A2"]]], [:row, [:sheet_reference, :"sheet1", [:cell, :"A3"]]]]
    input = [:prefix, :+, array] 
    expected = [:prefix, :+, [:sheet_reference, :"sheet1", [:cell, :"A2"]]]
    r.map(input).should == expected
  end

  it "should work with arrays inside prefixes inside arithmetic" do
    r = ReplaceArraysWithSingleCellsAst.new
    r.ref = [:sheet1, :B2]

    array = [:array, [:row, [:sheet_reference, :"sheet1", [:cell, :"A2"]]], [:row, [:sheet_reference, :"sheet1", [:cell, :"A3"]]]]
    input = [:arithmetic, [:prefix, :+, array], [:operator, :-], [:number, 1.0]]
    expected = [:arithmetic, [:prefix, :+, [:sheet_reference, :"sheet1", [:cell, :"A2"]]], [:operator, :-], [:number, 1.0]]
    r.map(input).should == expected
  end

  it "should work with functions inside arithmetic" do 
    r = ReplaceArraysWithSingleCellsAst.new
    r.ref = [:sheet1, :A1]
    array1 = [:array, [:row, [:sheet_reference, :"sheet1", [:cell, :"A1"]], [:sheet_reference, :"sheet1", [:cell, :"B1"]]]]
    array2 = [:array, [:row, [:sheet_reference, :"sheet1", [:cell, :"A2"]], [:sheet_reference, :"sheet1", [:cell, :"B2"]]]]
    array3 = [:array, [:row, [:sheet_reference, :"sheet1", [:cell, :"A3"]], [:sheet_reference, :"sheet1", [:cell, :"B3"]]]]
    input = [:arithmetic, [:function, :INDEX, array1, [:number, 0], array2], [:operator, :-], array3]
    expected = [:arithmetic, [:function, :INDEX, array1, [:number, 0], [:sheet_reference, :"sheet1", [:cell, :"A2"]]], [:operator, :-], [:sheet_reference, :"sheet1", [:cell, :"A3"]]]
    actual = r.map(input)
    actual.should == expected
  end

end
