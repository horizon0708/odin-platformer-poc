# Default recipe to run when just is called without arguments
default: run

# Build the Odin project
run:
    odin run game

# Clean build artifacts
clean:
    rm -rf bin/*