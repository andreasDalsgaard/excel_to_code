require_relative '../spec_helper'

describe ExcelToRuby do
  
  it "Should transform ExampleSpreadsheet.xlsx into the desired ruby code" do
    excel = File.join(File.dirname(__FILE__),'..','test_data','ExampleSpreadsheet.xlsx')
    expected = File.join(File.dirname(__FILE__),'excel_to_X_output_expected')
    actual = File.join(File.dirname(__FILE__),'excel_to_X_output_actual')
    puts "Writing to #{actual}"
    command = ExcelToRuby.new
    command.excel_file = excel
    command.output_directory = File.join(actual,'ruby')
    command.output_name = "RubyExampleSpreadsheet"
    #command.cells_that_can_be_set_at_runtime = {
    #  'Referencing' => ['A4']
    #}
    command.go!
    test_file = File.join(actual,'c','test_examplespreadsheet.rb')
    expect(system("ruby \"#{test_file}\"")).to be true
  end
end
