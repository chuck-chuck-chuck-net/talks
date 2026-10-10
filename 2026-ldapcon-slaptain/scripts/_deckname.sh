# Sourced helper: sets DECK to the deck's artifact basename.
# Single source of truth is the "name" field of package.json.
deck_name() {
  node -e 'process.stdout.write(require("./package.json").name)' 2>/dev/null \
    || basename "$PWD"
}
