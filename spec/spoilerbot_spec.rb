require './lib/spoilerbot.rb'
require 'rot13'

RSpec.describe "spoilerbot" do
	context "when using the standard spoiler" do
		it "correctly encodes the spoiler" do
			spoiler = "test"
			encoded_text = SpoilerBotEncoder.enc_standard("[spoiler]#{spoiler}[/spoiler]")

			expect(encoded_text).to eq("**grfg**")
		end

		it "correctly encodes multiple spoilers" do
			spoilered_text = "[spoiler]this[/spoiler] is a [spoiler]test[/spoiler] [spoiler]case[/spoiler]"
			encoded_text = SpoilerBotEncoder.enc_standard(spoilered_text)
			expected_text = "**guvf** is a **grfg** **pnfr**"

			expect(encoded_text).to eq(expected_text)
		end

		it "can deal with accented characters" do
			spoiler = "Pchnąć w tę łódź jeża lub ośm skrzyń fig."

			encoded_text = SpoilerBotEncoder.enc_standard("[spoiler]#{spoiler}[/spoiler]")

			expect(encoded_text).to eq("**Cpuaąć j gę łóqź wrżn yho bśz fxemlń svt.**")
		end

		it "can deal with non-alphanumeric characters" do
			spoiler = "@$test&+test"
			encoded_text = SpoilerBotEncoder.enc_standard("[spoiler]#{spoiler}[/spoiler]")

			expect(encoded_text).to eq("**@$grfg&+grfg**")
		end
	end

	context "when using the modern spoiler" do
		it "correctly encodes the spoiler" do
			description = "a huge spoiler"
			spoiler = "this test will pass"
			encoded_text = SpoilerBotEncoder.enc_modern("[#{description}]:[#{spoiler}]")

			expect(encoded_text).to eq("*a huge spoiler:* **guvf grfg jvyy cnff**")
		end

		it "correctly encodes multiple spoilers" do
			spoilered_text = "[one]:[test] and [two]:[test] please"
			encoded_text = SpoilerBotEncoder.enc_modern(spoilered_text)
			expected_text = "*one:* **grfg** and *two:* **grfg** please"

			expect(encoded_text).to eq(expected_text)
		end

		it "can deal with accented characters" do
			spoilered_text = "[pl]:[Pchnąć w tę łódź jeża lub ośm skrzyń fig.]"

			encoded_text = SpoilerBotEncoder.enc_modern(spoilered_text)

			expect(encoded_text).to eq("*pl:* **Cpuaąć j gę łóqź wrżn yho bśz fxemlń svt.**")
		end
	end

	context "decoding" do
		it "correctly decodes the spoiler" do
			decoded_text = SpoilerBotEncoder.decode("**grfg**")

			expect(decoded_text).to eq("**test**")
		end

		it "correctly decodes the spoiler with non-alphanumeric characters and diacritic signs" do
			decoded_text = SpoilerBotEncoder.decode("**grfg%ą&$grfg~!**")

			expect(decoded_text).to eq("**test%ą&$test~!**")
		end
	end

	context "database" do
		it "expects database to exist" do 
			expect(File.exist?('spoilerbot_configs.db')).to eq(true)
		end
	end
end