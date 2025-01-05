# Default recipe to run when just is called without arguments
default: run

# Build the Odin project
run:
    odin run game -out:bin/game

watch:
    ls **/*.odin | entr -cr just run

# Clean build artifacts
clean:
    rm -rf bin/*