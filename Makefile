
install:
	# Update and build
	swift package update
	swift build -c release --product SlurpCLI
	# Move repo for local referencing
	mkdir -p ~/.slurp/
	rm -rf ~/.slurp/clone
	cp -R ./ ~/.slurp/clone
	# Copy over bin file
	rm /usr/local/bin/slurp
	cp -f .build/release/SlurpCLI /usr/local/bin/slurp
