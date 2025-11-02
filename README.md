# Some Homebrew formulae i want

## How do I install these formulae?
`brew install toothbrush/throwaway/<formula>`

Or `brew tap toothbrush/throwaway` and then `brew install <formula>`.

## How to update a formula?

Update the URL and SHA256 sum of the file.  For instance, update the `url` field to the new
tag-tarball.  Find the new SHA256 sum:

```bash
curl -Ls "https://github.com/toothbrush/clitotp-go/archive/refs/tags/v0.3.1.tar.gz" | sha256sum
=>
10e76c54c5087ebf114a57c28566d45b39bb82692a37afbe75d02203123bd699  -
```

Before committing you can test your changes with:

```bash
brew install --build-from-source --verbose --debug --formula ./Formula/clitotp-go.rb
```

## Documentation
`brew help`, `man brew` or check [Homebrew's documentation](https://docs.brew.sh).

## For the Cask

This bit of documentation was useful: https://github.com/Homebrew/homebrew-cask/blob/master/CONTRIBUTING.md#getting-set-up-to-contribute.

```sh
cd "$(brew --repository)"/Library/Taps/toothbrush/homebrew-toothbrush
git checkout -b new-feature
```
