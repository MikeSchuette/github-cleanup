# github-cleanup

You've got a lot of repos.  Like, thousands.  Some of them probably aren't used any more, or never were.  How do you find the dead weight?

Github's API is not informative enough to help you, so these scripts will:
1. Retrieve the full list of repos in your Github organization.
2. Clone them all locally, and checkout whichever branch has the latest commit.
3. Assign a weight ("heat") to each repo for how likely it is to be useless, and aggregate those stats into a CSV file for ease of cajoling your coworkers.



## Usage
1. Clone this repo to somewhere with lots of space.
2. Have [jq](https://stedolan.github.io/jq/) somewhere on your PATH, or inside this dir.
2. Set environment variables `GITHUB_ORG` and `GITHUB_TOKEN`
3. `./do_everything.sh`

The code will clone all repos to `./repos`, and generate data files in `./stats/TODAY/TODAY.csv`.

## TODO
- Pass "created_at" through the pipeline
- Move the "ignore recently-created repos" code into make_staleness_stats.sh so all stats options are in one place
- Create a whitelist facility
- Support stdin/out
